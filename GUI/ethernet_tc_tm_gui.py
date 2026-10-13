#!/usr/bin/env python3
"""
Threaded Ethernet Telecommand/Telemetry GUI for Mercury XU5 PE1 tests.

Cumulative-history ADC plotting revision.

- Socket receive/send runs in a background thread.
- Tkinter and matplotlib stay only in the main GUI thread.
- Incoming telemetry is processed in small batches so the GUI does not freeze.
- Text logging is throttled and limited.
- Plot redraw is throttled.
- ADC telemetry DATA is decoded as: CH | SAMPLE_MSB | SAMPLE_LSB.
- AD7266 codes are displayed in volts using configurable VREF and RANGE.
- The 16-bit FPGA timestamp is unwrapped and used as the x-axis of every ADC telemetry plot.
- ADC plots retain past values and progressively compact the complete retained history as time increases.
- Every ADC plot supports persistent rectangle (box) zoom without losing the selected view during live updates.
- Open selected starts a live capture immediately and displays a model-matched AD7266 recent view.
- ADC x-coordinates are uniformly reconstructed from coarse FPGA frame timestamps to preserve waveform shape.
"""

from __future__ import annotations

import csv
import math
import queue
import socket
import threading
import time
from collections import deque
from dataclasses import dataclass
import tkinter as tk
from tkinter import ttk, messagebox, filedialog

try:
    from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg, NavigationToolbar2Tk
    from matplotlib.figure import Figure
    HAS_MATPLOTLIB = True
except Exception:
    FigureCanvasTkAgg = None
    NavigationToolbar2Tk = None
    Figure = None
    HAS_MATPLOTLIB = False


VERSION = 0x01
SOURCE_SPIKE = 0x00
SOURCE_HPU = 0x09
DAC_SOURCES = {"DAC1": 0x01, "DAC2": 0x02, "DAC3": 0x03, "DAC4": 0x04}
DAC_CHANNELS = tuple("ABCDEFGH")
DAC_MAX_SAMPLES = 125
DAC_DEFAULT_SAMPLE_PERIOD_TICKS = 100000
DAC_DEFAULT_FPGA_CLOCK_HZ = 100_000_000.0
DAC_DEFAULT_FULL_SCALE_VOLTS = 1.8
DAC_DEFAULT_FREQUENCY_HZ = 1000.0
DAC_DEFAULT_SAMPLE_COUNT = 125
DAC_WAVEFORM_TYPES = ("Sine", "Cosine", "Pulse", "Triangle")
ADC_SOURCES = {"ADC1": 0x05, "ADC2": 0x06, "ADC3": 0x07, "ADC4": 0x08}
SOURCE_LABEL_BY_VALUE = {SOURCE_SPIKE: "Spikeulike"}
SOURCE_LABEL_BY_VALUE.update({v: k for k, v in DAC_SOURCES.items()})
SOURCE_LABEL_BY_VALUE.update({v: k for k, v in ADC_SOURCES.items()})
SOURCE_LABEL_BY_VALUE[SOURCE_HPU] = "HPU Core"
TAB_BY_SOURCE = {SOURCE_SPIKE: "Spikeulike"}
for value in DAC_SOURCES.values():
    TAB_BY_SOURCE[value] = "DAC"
for value in ADC_SOURCES.values():
    TAB_BY_SOURCE[value] = "ADC"
TAB_BY_SOURCE[SOURCE_HPU] = "HPU Core"

ADC_PAIR_CHANNELS = ((1, 7), (2, 8), (3, 9), (4, 10), (5, 11), (6, 12))
ADC_PAIR_LABELS = tuple((f"Pair {idx + 1}", f"CH{a} + CH{b}") for idx, (a, b) in enumerate(ADC_PAIR_CHANNELS))

SUPPORTED_MODES = ("UDP", "TCP")
TM_HEADER_BYTES = 6
TC_HEADER_BYTES = 4
RECV_BUFFER_LIMIT = 65536
RX_QUEUE_MAX = 50000
TX_QUEUE_MAX = 1000
MAX_PACKETS_PER_UI_TICK = 200
UI_QUEUE_INTERVAL_MS = 15
LOG_FLUSH_INTERVAL_MS = 150
PLOT_REFRESH_INTERVAL_MS = 150
MAX_LOG_LINES_PER_BOX = 1000
MAX_LOG_LINES_PER_FLUSH = 80
# Retain a long cumulative history for every ADC channel.  The displayed plot
# spans the complete retained history and uses min/max-preserving compaction
# only when the number of values becomes too large for responsive rendering.
ADC_MAX_PLOT_POINTS = 250000
ADC_GRID_MAX_RENDER_POINTS = 1800
ADC_SINGLE_MAX_RENDER_POINTS = 7000
ADC_SUMMARY_INTERVAL = 17
ADC_RESOLUTION_BITS = 12
ADC_FULL_SCALE_COUNTS = 1 << ADC_RESOLUTION_BITS
ADC_SAMPLE_MAX = ADC_FULL_SCALE_COUNTS - 1

# Exact ADC3 sine-model configuration implemented in AD7266_SPI_SINE_MODEL.
# The model advances one 64-entry LUT phase per conversion. DOUTB is shifted
# by 16 LUT entries (90 degrees), and adjacent address pairs are shifted by
# three LUT entries (16.875 degrees).
ADC3_MODEL_LUT = (
    0x800, 0x8B0, 0x95F, 0xA0B, 0xAB1, 0xB51, 0xBE8, 0xC76,
    0xCF9, 0xD6F, 0xDD9, 0xE33, 0xE7F, 0xEBA, 0xEE5, 0xEFF,
    0xF08, 0xEFF, 0xEE5, 0xEBA, 0xE7F, 0xE33, 0xDD9, 0xD6F,
    0xCF9, 0xC76, 0xBE8, 0xB51, 0xAB1, 0xA0B, 0x95F, 0x8B0,
    0x800, 0x750, 0x6A1, 0x5F5, 0x54F, 0x4AF, 0x418, 0x38A,
    0x307, 0x291, 0x227, 0x1CD, 0x181, 0x146, 0x11B, 0x101,
    0x0F8, 0x101, 0x11B, 0x146, 0x181, 0x1CD, 0x227, 0x291,
    0x307, 0x38A, 0x418, 0x4AF, 0x54F, 0x5F5, 0x6A1, 0x750,
)
ADC3_MODEL_PHASE_STEP = 1
ADC3_MODEL_PAIR_PHASE_OFFSET = 3
ADC3_MODEL_DOUTB_PHASE_OFFSET = 16
ADC3_MODEL_RECENT_CYCLES = 4
ADC_SINGLE_VIEW_RECENT = "Recent live / AD7266 model"
ADC_SINGLE_VIEW_FULL = "Full retained history"

# AD7266 defaults from the datasheet.
# RANGE=0 -> 0..VREF, RANGE=1 -> 0..2*VREF.
ADC_DEFAULT_VREF_VOLTS = 2.5
ADC_RANGE_OPTIONS = {
    "0..VREF (RANGE=0)": 1.0,
    "0..2*VREF (RANGE=1)": 2.0,
}

# fpga_timestamp_timer_16 default: 100 MHz / 100000 = 1 kHz,
# therefore one 16-bit timestamp count equals 1 ms.
FPGA_TIMESTAMP_BITS = 16
FPGA_TIMESTAMP_MODULUS = 1 << FPGA_TIMESTAMP_BITS
FPGA_TIMESTAMP_DEFAULT_TICK_SECONDS = 0.001

# HPU Core Ethernet command protocol and register map.
HPU_CMD_WRITE = 0x01
HPU_CMD_READ = 0x02
HPU_TM_EVENT = 0x40
HPU_TM_WRITE_RESPONSE = 0x81
HPU_TM_READ_RESPONSE = 0x82
HPU_TM_ERROR = 0xE0
HPU_EVENT_ADDRESS_MASK = 0x1FF
HPU_EVENT_HISTORY_LIMIT = 250000
HPU_RECENT_EVENT_ROWS = 500
HPU_RATE_WINDOW_SECONDS = 30.0
HPU_RATE_BIN_SECONDS = 0.5
HPU_DEFAULT_AUTO_STATUS_MS = 500

# Addresses are byte offsets on the HPU AXI-Lite interface.
HPU_REGISTER_MAP = (
    (0x00, "CTRL", "R/W", "Global control; bit13 OnlyEventsRx, bit1 AXI-stream enable"),
    (0x04, "LPBK_CNFG", "R/W", "Left/right HSSAER loopback configuration"),
    (0x08, "RX_DATA", "R", "RX FIFO data"),
    (0x0C, "RX_TIME", "R", "RX FIFO timestamp"),
    (0x10, "TX_DATA", "R/W", "TX FIFO data"),
    (0x14, "DMA", "R/W", "DMA length and test configuration"),
    (0x18, "RAWSTAT", "R", "Raw interrupt and error status"),
    (0x1C, "IRQ", "R/WC", "Latched interrupt status; write one to clear"),
    (0x20, "IMASK", "R/W", "Interrupt mask"),
    (0x28, "WRAP_TIME", "R/WC", "Timestamp wrap counter; write clears"),
    (0x34, "HSSAER_STAT", "R", "HSSAER run status"),
    (0x38, "HSSAER_RX_ERR", "R/WC", "HSSAER RX error collector"),
    (0x3C, "HSSAER_RX_MSK", "R/W", "HSSAER RX error mask"),
    (0x40, "RX_CTRL", "R/W", "Left/right RX protocol enable"),
    (0x44, "TX_CTRL", "R/W", "TX protocol and timestamp control"),
    (0x48, "RX_CNFG", "R/W", "PAER polarity and handshake delays"),
    (0x4C, "TX_CNFG", "R/W", "TX PAER polarity"),
    (0x50, "IP_CONFIG", "R", "Synthesized protocol capabilities"),
    (0x54, "FIFO_THRESHOLD", "R/W", "RX FIFO threshold"),
    (0x58, "LPBK_CNFG_AUX", "R/W", "Auxiliary HSSAER loopback configuration"),
    (0x5C, "ID", "R", "Core identifier and version"),
    (0x60, "AUX_CTRL", "R/W", "Auxiliary RX protocol enable; bit1 AUX PAER"),
    (0x64, "HSSAER_AUX_RX_ERR", "R/WC", "Auxiliary HSSAER RX errors"),
    (0x68, "HSSAER_AUX_RX_MSK", "R/W", "Auxiliary HSSAER error mask"),
    (0x6C, "HSSAER_AUX_RX_ERR_THR", "R/W", "Auxiliary HSSAER error thresholds"),
    (0x70, "HSSAER_AUX_CH0_ERR_CNT", "R/C", "Auxiliary HSSAER channel 0 counters"),
    (0x74, "HSSAER_AUX_CH1_ERR_CNT", "R/C", "Auxiliary HSSAER channel 1 counters"),
    (0x78, "HSSAER_AUX_CH2_ERR_CNT", "R/C", "Auxiliary HSSAER channel 2 counters"),
    (0x7C, "HSSAER_AUX_CH3_ERR_CNT", "R/C", "Auxiliary HSSAER channel 3 counters"),
    (0x80, "SPNN_START_KEY", "R/W", "SpiNNaker START key"),
    (0x84, "SPNN_STOP_KEY", "R/W", "SpiNNaker STOP key"),
    (0x88, "SPNN_TX_MASK", "R/W", "SpiNNaker TX mask"),
    (0x8C, "SPNN_RX_MASK", "R/W", "SpiNNaker RX mask"),
    (0x90, "SPNN_CTRL", "R/W", "SpiNNaker control"),
    (0x94, "SPNN_STATUS", "R", "SpiNNaker status"),
    (0xA0, "TLAST_TIMEOUT", "R/W", "AXI-stream TLAST timeout"),
    (0xA4, "TLAST_COUNT", "R", "AXI-stream TLAST counter"),
    (0xA8, "TDATA_COUNT", "R", "AXI-stream data counter"),
    (0xB0, "GTRX_LEFT", "R", "Left transceiver status"),
    (0xB4, "GTRX_RIGHT", "R", "Right transceiver status"),
    (0xB8, "GTRX_AUX", "R", "Auxiliary transceiver status"),
    (0xBC, "GTTX", "R", "TX transceiver status"),
)
HPU_REGISTER_BY_ADDRESS = {address: (name, access, description) for address, name, access, description in HPU_REGISTER_MAP}
HPU_STATUS_POLL_ADDRESSES = (0x00, 0x18, 0x40, 0x48, 0x50, 0x5C, 0x60, 0xA4, 0xA8)

# Locked project configuration: active-low PAER handshake, sample delay 1,
# ACK set delay 0, ACK release delay 2, AUX PAER enabled, AXI-stream enabled,
# and RX output reduced to raw event words.
HPU_PROJECT_CONFIGURATION = (
    (0x48, 0x02000100, 0x0F, "RX_CNFG: active-low PAER, sample=1, ack_set=0, ack_release=2"),
    (0x60, 0x00000002, 0x0F, "AUX_CTRL: enable Auxiliary PAER only"),
    (0x00, 0x00002002, 0x0F, "CTRL: OnlyEventsRx=1 and AXI-stream interface enabled"),
)


@dataclass
class ParsedPacket:
    kind: str
    total_len: int
    source: int
    payload: bytes
    meta: dict


class ToolTip:
    """Small delayed help popup shown when the pointer rests on a widget."""

    def __init__(
        self,
        widget,
        text: str,
        delay_ms: int = 500,
        wraplength: int = 360,
    ):
        self.widget = widget
        self.text = text
        self.delay_ms = delay_ms
        self.wraplength = wraplength
        self._after_id = None
        self._window = None

        widget.bind("<Enter>", self._schedule, add="+")
        widget.bind("<Leave>", self._hide, add="+")
        widget.bind("<ButtonPress>", self._hide, add="+")
        widget.bind("<Destroy>", self._hide, add="+")

    def _schedule(self, _event=None):
        self._cancel_schedule()
        self._after_id = self.widget.after(self.delay_ms, self._show)

    def _cancel_schedule(self):
        if self._after_id is not None:
            try:
                self.widget.after_cancel(self._after_id)
            except Exception:
                pass
            self._after_id = None

    def _show(self):
        self._after_id = None
        if self._window is not None or not self.text:
            return
        try:
            x = self.widget.winfo_pointerx() + 14
            y = self.widget.winfo_pointery() + 18
        except Exception:
            return

        window = tk.Toplevel(self.widget)
        window.wm_overrideredirect(True)
        try:
            window.wm_attributes("-topmost", True)
        except tk.TclError:
            pass
        window.wm_geometry(f"+{x}+{y}")

        label = tk.Label(
            window,
            text=self.text,
            justify="left",
            anchor="w",
            relief="solid",
            borderwidth=1,
            padx=8,
            pady=6,
            wraplength=self.wraplength,
            background="#fffbe6",
            foreground="#202020",
        )
        label.pack()
        self._window = window

    def _hide(self, _event=None):
        self._cancel_schedule()
        if self._window is not None:
            try:
                self._window.destroy()
            except Exception:
                pass
            self._window = None


def add_tooltip(widget, text: str, delay_ms: int = 500):
    """Attach a ToolTip and retain it for the lifetime of the widget."""
    tooltip = ToolTip(widget, text=text, delay_ms=delay_ms)
    widget._tooltip = tooltip
    return tooltip


def clean_hex_string(text: str) -> str:
    text = text.replace("0x", " ").replace("0X", " ")
    for ch in [",", ";", "_", "\n", "\r", "\t", "-"]:
        text = text.replace(ch, " ")
    return " ".join(text.split())


def parse_hex_bytes(text: str) -> bytes:
    normalized = clean_hex_string(text)
    if not normalized:
        return b""
    parts = normalized.split()
    if len(parts) == 1 and len(parts[0]) > 2:
        raw = parts[0]
        if len(raw) % 2:
            raise ValueError("Continuous HEX must have an even number of digits.")
        parts = [raw[i:i + 2] for i in range(0, len(raw), 2)]
    out = bytearray()
    for part in parts:
        if len(part) > 2:
            raise ValueError(f"'{part}' is more than one byte.")
        try:
            value = int(part, 16)
        except ValueError as exc:
            raise ValueError(f"'{part}' is not valid HEX.") from exc
        if not 0 <= value <= 0xFF:
            raise ValueError(f"'{part}' is outside 00..FF.")
        out.append(value)
    return bytes(out)


def bytes_to_hex(data: bytes) -> str:
    return " ".join(f"{b:02X}" for b in data)


def parse_hex_words(text: str) -> list[int]:
    """Parse unsigned 16-bit sample words written in hexadecimal."""
    normalized = text.replace("0x", " ").replace("0X", " ")
    for ch in [",", ";", "_", "\n", "\r", "\t", "-"]:
        normalized = normalized.replace(ch, " ")
    parts = normalized.split()
    if not parts:
        return []

    if len(parts) == 1 and len(parts[0]) > 4:
        raw = parts[0]
        if len(raw) % 4:
            raise ValueError(
                "Continuous 16-bit sample HEX must contain a multiple of four digits."
            )
        parts = [raw[i:i + 4] for i in range(0, len(raw), 4)]

    words = []
    for part in parts:
        if len(part) > 4:
            raise ValueError(f"'{part}' is more than one 16-bit sample word.")
        try:
            value = int(part, 16)
        except ValueError as exc:
            raise ValueError(f"'{part}' is not a valid 16-bit HEX sample.") from exc
        if not 0 <= value <= 0xFFFF:
            raise ValueError(f"'{part}' is outside 0000..FFFF.")
        words.append(value)
    return words


def calculate_dac_period_ticks(
    fpga_clock_hz: float, frequency_hz: float, sample_count: int
) -> tuple[int, float, float]:
    """Return integer sample-period ticks, achieved frequency, and sample rate."""
    if fpga_clock_hz <= 0.0:
        raise ValueError("FPGA clock must be greater than zero.")
    if frequency_hz <= 0.0:
        raise ValueError("Waveform frequency must be greater than zero.")
    if not 1 <= sample_count <= DAC_MAX_SAMPLES:
        raise ValueError(
            f"Samples per cycle must be 1..{DAC_MAX_SAMPLES}."
        )

    ideal_ticks = fpga_clock_hz / (frequency_hz * sample_count)
    period_ticks = int(round(ideal_ticks))
    if not 1 <= period_ticks <= 0xFFFFFFFF:
        minimum = fpga_clock_hz / (0xFFFFFFFF * sample_count)
        maximum = fpga_clock_hz / sample_count
        raise ValueError(
            "Requested frequency cannot be represented by the 32-bit sample "
            f"period. Valid range is approximately {minimum:.9g}..{maximum:.9g} Hz "
            f"for {sample_count} samples/cycle."
        )

    sample_rate_hz = fpga_clock_hz / period_ticks
    achieved_frequency_hz = sample_rate_hz / sample_count
    return period_ticks, achieved_frequency_hz, sample_rate_hz


def generate_dac_waveform_samples(
    waveform: str,
    sample_count: int,
    maximum_amplitude_volts: float,
    full_scale_volts: float,
    pulse_duty_percent: float = 50.0,
) -> tuple[list[int], list[float]]:
    """Generate one unipolar waveform cycle and its 16-bit DAC codes."""
    if waveform not in DAC_WAVEFORM_TYPES:
        raise ValueError(f"Unsupported waveform: {waveform}")
    if not 1 <= sample_count <= DAC_MAX_SAMPLES:
        raise ValueError(
            f"Samples per cycle must be 1..{DAC_MAX_SAMPLES}."
        )
    if full_scale_volts <= 0.0:
        raise ValueError("DAC full-scale voltage must be greater than zero.")
    if not 0.0 <= maximum_amplitude_volts <= full_scale_volts:
        raise ValueError(
            f"Maximum amplitude must be between 0 and {full_scale_volts:g} V."
        )
    if not 0.0 < pulse_duty_percent < 100.0:
        raise ValueError("Pulse duty cycle must be greater than 0 and less than 100 percent.")

    duty = pulse_duty_percent / 100.0
    codes: list[int] = []
    voltages: list[float] = []

    for index in range(sample_count):
        phase = index / sample_count
        angle = 2.0 * math.pi * phase

        if waveform == "Sine":
            normalized = 0.5 * (math.sin(angle) + 1.0)
        elif waveform == "Cosine":
            normalized = 0.5 * (math.cos(angle) + 1.0)
        elif waveform == "Pulse":
            normalized = 1.0 if phase < duty else 0.0
        else:  # Triangle
            normalized = 1.0 - abs(2.0 * phase - 1.0)

        voltage = maximum_amplitude_volts * normalized
        code = int(round((voltage / full_scale_volts) * 0xFFFF))
        code = max(0, min(0xFFFF, code))
        voltages.append(voltage)
        codes.append(code)

    return codes, voltages


def now_stamp() -> str:
    return time.strftime("%H:%M:%S")


def tc_length_from_payload_size(payload_size: int) -> int:
    if payload_size < 1:
        raise ValueError("At least 1 DATA byte is required.")
    if payload_size > 256:
        raise ValueError("Payload too long. DATA_LENGTH supports max 256 DATA bytes.")
    return payload_size - 1


def payload_size_from_length(length_field: int) -> int:
    return length_field + 1


def adc_channel_name(ch: int) -> str:
    return f"CH{ch}"


def adc_code_to_voltage(adc_code: int, vref_volts: float, range_multiplier: float) -> float:
    """Convert one 12-bit AD7266 straight-binary code to volts."""
    code = max(0, min(ADC_SAMPLE_MAX, int(adc_code)))
    return code * float(vref_volts) * float(range_multiplier) / float(ADC_FULL_SCALE_COUNTS)


def decode_adc_payload_triples(payload: bytes) -> tuple[list[tuple[int, int, bytes]], str]:
    warning = ""
    if not payload:
        return [], "empty ADC telemetry payload"
    usable = len(payload) - (len(payload) % 3)
    if usable != len(payload):
        warning = f"ADC telemetry payload length {len(payload)} is not a multiple of 3; using first {usable} bytes"
        payload = payload[:usable]
    decoded = []
    for idx in range(0, len(payload), 3):
        raw = payload[idx:idx + 3]
        ch = raw[0]
        sample = ((raw[1] << 8) | raw[2]) & ADC_SAMPLE_MAX
        decoded.append((ch, sample, raw))
    return decoded, warning


class TrafficTab:
    def __init__(self, app, notebook: ttk.Notebook, name: str, can_send: bool):
        self.app = app
        self.name = name
        self.can_send = can_send
        self.pending_log = []
        self.frame = ttk.Frame(notebook, padding=10)
        notebook.add(self.frame, text=name)
        self.frame.columnconfigure(0, weight=1)
        self.frame.rowconfigure(3, weight=1)
        row = 0
        header = ttk.Frame(self.frame)
        header.grid(row=row, column=0, sticky="ew")
        header.columnconfigure(4, weight=1)
        ttk.Label(header, text=f"{name}").grid(row=0, column=0, sticky="w")
        self.source_var = None
        if can_send and name == "DAC":
            ttk.Label(header, text="DAC:").grid(row=0, column=1, sticky="e", padx=(12, 4))
            self.source_var = tk.StringVar(value="DAC1")
            combo = ttk.Combobox(header, textvariable=self.source_var, values=list(DAC_SOURCES.keys()), state="readonly", width=8)
            combo.grid(row=0, column=2, sticky="w")
        elif can_send and name == "Spikeulike":
            ttk.Label(header, text="Source = 0x00").grid(row=0, column=1, sticky="w", padx=(12, 0))
        if can_send:
            row += 1
            input_box = ttk.LabelFrame(self.frame, text="DATA input, HEX bytes only")
            input_box.grid(row=row, column=0, sticky="nsew", pady=(8, 8))
            input_box.columnconfigure(0, weight=1)
            self.input_text = tk.Text(input_box, height=5, wrap="word", undo=True)
            self.input_text.grid(row=0, column=0, sticky="nsew", padx=6, pady=6)
            buttons = ttk.Frame(input_box)
            buttons.grid(row=1, column=0, sticky="ew", padx=6, pady=(0, 6))
            buttons.columnconfigure(3, weight=1)
            ttk.Button(buttons, text="Send", command=self.send_clicked).grid(row=0, column=0, padx=(0, 6))
            ttk.Button(buttons, text="Clear input", command=lambda: self.input_text.delete("1.0", "end")).grid(row=0, column=1, padx=(0, 6))
            ttk.Button(buttons, text="Build preview", command=self.preview_clicked).grid(row=0, column=2, padx=(0, 6))
            self.preview_var = tk.StringVar(value="TX preview: -")
            ttk.Label(buttons, textvariable=self.preview_var).grid(row=0, column=3, sticky="w")
        else:
            row += 1
            ttk.Label(self.frame, text="Receive-only tab for global or unknown packets.").grid(row=row, column=0, sticky="w", pady=(8, 8))
        row += 1
        rx_box = ttk.LabelFrame(self.frame, text="Received / echo / telemetry")
        rx_box.grid(row=row, column=0, sticky="nsew")
        rx_box.columnconfigure(0, weight=1)
        rx_box.rowconfigure(0, weight=1)
        self.frame.rowconfigure(row, weight=1)
        self.rx_text = tk.Text(rx_box, height=16, wrap="word", state="disabled")
        self.rx_text.grid(row=0, column=0, sticky="nsew", padx=(6, 0), pady=6)
        scrollbar = ttk.Scrollbar(rx_box, orient="vertical", command=self.rx_text.yview)
        scrollbar.grid(row=0, column=1, sticky="ns", padx=(0, 6), pady=6)
        self.rx_text.configure(yscrollcommand=scrollbar.set)
        row += 1
        ttk.Button(self.frame, text="Clear received box", command=self.clear_rx).grid(row=row, column=0, sticky="e", pady=(8, 0))

    def get_source(self) -> int:
        if self.name == "Spikeulike":
            return SOURCE_SPIKE
        if self.name == "DAC" and self.source_var is not None:
            return DAC_SOURCES[self.source_var.get()]
        raise RuntimeError(f"{self.name} cannot send.")

    def build_packet_from_input(self) -> bytes:
        payload = parse_hex_bytes(self.input_text.get("1.0", "end"))
        length = tc_length_from_payload_size(len(payload))
        seq = self.app.pack_seq & 0xFF
        return bytes([VERSION, seq, self.get_source(), length]) + payload

    def preview_clicked(self):
        try:
            pkt = self.build_packet_from_input()
            self.preview_var.set(f"TX preview: {bytes_to_hex(pkt)}")
        except Exception as exc:
            messagebox.showerror("Packet error", str(exc))

    def send_clicked(self):
        try:
            pkt = self.build_packet_from_input()
            self.app.queue_packet_for_send(pkt, self.name)
            self.preview_var.set(f"Sent/queued: {bytes_to_hex(pkt)}")
        except Exception as exc:
            messagebox.showerror("Send error", str(exc))

    def append_rx(self, line: str):
        self.pending_log.append(line)

    def clear_rx(self):
        self.rx_text.configure(state="normal")
        self.rx_text.delete("1.0", "end")
        self.rx_text.configure(state="disabled")
        self.pending_log.clear()

    def flush_pending_logs(self):
        if not self.pending_log:
            return
        lines = self.pending_log[:MAX_LOG_LINES_PER_FLUSH]
        del self.pending_log[:MAX_LOG_LINES_PER_FLUSH]
        self.rx_text.configure(state="normal")
        for line in lines:
            self.rx_text.insert("end", line + "\n")
        self.trim_text_widget()
        self.rx_text.see("end")
        self.rx_text.configure(state="disabled")

    def trim_text_widget(self):
        try:
            line_count = int(self.rx_text.index("end-1c").split(".")[0])
            if line_count > MAX_LOG_LINES_PER_BOX:
                delete_to = line_count - MAX_LOG_LINES_PER_BOX + 1
                self.rx_text.delete("1.0", f"{delete_to}.0")
        except Exception:
            pass



class DacMainTab:
    """Waveform generator and DAC8568 packet builder matching the HDL parser."""

    def __init__(self, app, notebook: ttk.Notebook):
        self.app = app
        self.pending_log = []
        self.generated_samples: list[int] = []
        self.generated_voltages: list[float] = []
        self.generated_period_ticks = 0
        self.generated_frequency_hz = 0.0
        self.generated_sample_rate_hz = 0.0

        self.frame = ttk.Frame(notebook, padding=10)
        notebook.add(self.frame, text="DAC")
        self.frame.columnconfigure(0, weight=1)
        self.frame.rowconfigure(7, weight=1)

        help_hint = ttk.Label(
            self.frame,
            text="Move the mouse pointer over a DAC option or button to display a short explanation.",
        )
        help_hint.grid(row=0, column=0, sticky="w", pady=(0, 6))

        selection = ttk.LabelFrame(self.frame, text="Physical DAC and output channel")
        selection.grid(row=1, column=0, sticky="ew", pady=(0, 8))
        selection.columnconfigure(8, weight=1)

        ttk.Label(selection, text="Physical DAC").grid(
            row=0, column=0, sticky="e", padx=(8, 4), pady=8
        )
        self.dac_var = tk.StringVar(value="DAC1")
        dac_combo = ttk.Combobox(
            selection,
            textvariable=self.dac_var,
            values=list(DAC_SOURCES.keys()),
            state="readonly",
            width=8,
        )
        dac_combo.grid(row=0, column=1, sticky="w", padx=(0, 14), pady=8)
        dac_combo.bind("<<ComboboxSelected>>", lambda _event: self.refresh_generated_waveform())
        add_tooltip(
            dac_combo,
            "Select the physical DAC device. DAC1..DAC4 map to Ethernet SOURCE_ID values 0x01..0x04.",
        )

        ttk.Label(selection, text="Channel").grid(
            row=0, column=2, sticky="e", padx=(0, 4), pady=8
        )
        self.channel_var = tk.StringVar(value="A")
        channel_combo = ttk.Combobox(
            selection,
            textvariable=self.channel_var,
            values=DAC_CHANNELS,
            state="readonly",
            width=5,
        )
        channel_combo.grid(row=0, column=3, sticky="w", padx=(0, 14), pady=8)
        channel_combo.bind("<<ComboboxSelected>>", lambda _event: self.refresh_generated_waveform())
        add_tooltip(
            channel_combo,
            "Select DAC8568 output channel A..H. The HDL load command uses channel indices 0x00..0x07.",
        )

        self.source_hint_var = tk.StringVar()
        ttk.Label(selection, textvariable=self.source_hint_var).grid(
            row=0, column=8, sticky="w", padx=8, pady=8
        )

        waveform_box = ttk.LabelFrame(
            self.frame,
            text="Waveform generator: one cycle is stored in FPGA channel memory",
        )
        waveform_box.grid(row=2, column=0, sticky="ew", pady=(0, 8))
        for col in range(8):
            waveform_box.columnconfigure(col, weight=1 if col in (1, 3, 5, 7) else 0)

        ttk.Label(waveform_box, text="Waveform").grid(
            row=0, column=0, sticky="e", padx=(8, 4), pady=(8, 4)
        )
        self.waveform_var = tk.StringVar(value="Sine")
        waveform_combo = ttk.Combobox(
            waveform_box,
            textvariable=self.waveform_var,
            values=DAC_WAVEFORM_TYPES,
            state="readonly",
            width=11,
        )
        waveform_combo.grid(row=0, column=1, sticky="w", padx=(0, 12), pady=(8, 4))
        waveform_combo.bind("<<ComboboxSelected>>", self.waveform_type_changed)
        add_tooltip(
            waveform_combo,
            "Choose the waveform stored as one cycle in FPGA memory: sine, cosine, pulse, or triangle.",
        )

        ttk.Label(waveform_box, text="Frequency (Hz)").grid(
            row=0, column=2, sticky="e", padx=(0, 4), pady=(8, 4)
        )
        self.frequency_var = tk.StringVar(value=f"{DAC_DEFAULT_FREQUENCY_HZ:g}")
        frequency_entry = ttk.Entry(waveform_box, textvariable=self.frequency_var, width=14)
        frequency_entry.grid(row=0, column=3, sticky="ew", padx=(0, 12), pady=(8, 4))
        add_tooltip(
            frequency_entry,
            "Requested output frequency in hertz. The GUI converts it to an integer SAMPLE_PERIOD_TICKS value using FPGA_clock / (frequency x samples_per_cycle).",
        )

        ttk.Label(waveform_box, text="Maximum amplitude (V)").grid(
            row=0, column=4, sticky="e", padx=(0, 4), pady=(8, 4)
        )
        self.amplitude_var = tk.StringVar(value="1.0")
        amplitude_entry = ttk.Entry(waveform_box, textvariable=self.amplitude_var, width=12)
        amplitude_entry.grid(row=0, column=5, sticky="ew", padx=(0, 12), pady=(8, 4))
        add_tooltip(
            amplitude_entry,
            "Maximum waveform voltage. The generated waveform is unipolar and ranges from 0 V to this value. It must not exceed DAC full scale.",
        )

        ttk.Label(waveform_box, text="Samples/cycle").grid(
            row=0, column=6, sticky="e", padx=(0, 4), pady=(8, 4)
        )
        self.sample_count_var = tk.StringVar(value=str(DAC_DEFAULT_SAMPLE_COUNT))
        sample_count_entry = ttk.Entry(waveform_box, textvariable=self.sample_count_var, width=8)
        sample_count_entry.grid(row=0, column=7, sticky="ew", padx=(0, 8), pady=(8, 4))
        add_tooltip(
            sample_count_entry,
            "Number of stored points for one waveform cycle. Allowed range is 1..125 because the HDL DATA payload is limited to 256 bytes.",
        )

        ttk.Label(waveform_box, text="FPGA clock (Hz)").grid(
            row=1, column=0, sticky="e", padx=(8, 4), pady=4
        )
        self.fpga_clock_var = tk.StringVar(value=f"{DAC_DEFAULT_FPGA_CLOCK_HZ:.0f}")
        fpga_clock_entry = ttk.Entry(waveform_box, textvariable=self.fpga_clock_var, width=14)
        fpga_clock_entry.grid(row=1, column=1, sticky="ew", padx=(0, 12), pady=4)
        add_tooltip(
            fpga_clock_entry,
            "Clock frequency driving the DAC waveform scheduler in the FPGA. Use the actual PL clock frequency; the current design normally uses 100 MHz.",
        )

        ttk.Label(waveform_box, text="DAC full scale (V)").grid(
            row=1, column=2, sticky="e", padx=(0, 4), pady=4
        )
        self.full_scale_var = tk.StringVar(value=f"{DAC_DEFAULT_FULL_SCALE_VOLTS:g}")
        full_scale_entry = ttk.Entry(waveform_box, textvariable=self.full_scale_var, width=12)
        full_scale_entry.grid(row=1, column=3, sticky="ew", padx=(0, 12), pady=4)
        add_tooltip(
            full_scale_entry,
            "Voltage represented by DAC code 0xFFFF. For the current external reference configuration, use 1.8 V.",
        )

        ttk.Label(waveform_box, text="Pulse duty (%)").grid(
            row=1, column=4, sticky="e", padx=(0, 4), pady=4
        )
        self.duty_var = tk.StringVar(value="50")
        self.duty_entry = ttk.Entry(waveform_box, textvariable=self.duty_var, width=10)
        self.duty_entry.grid(row=1, column=5, sticky="ew", padx=(0, 12), pady=4)
        add_tooltip(
            self.duty_entry,
            "Pulse high-time as a percentage of one cycle. This option is used only when Waveform is Pulse and must be between 0 and 100 percent.",
        )

        self.unipolar_hint_var = tk.StringVar(
            value="Generated waveforms are unipolar: 0 V to the selected maximum amplitude."
        )
        ttk.Label(
            waveform_box,
            textvariable=self.unipolar_hint_var,
            wraplength=430,
            justify="left",
        ).grid(row=1, column=6, columnspan=2, sticky="w", padx=(0, 8), pady=4)

        flags_frame = ttk.Frame(waveform_box)
        flags_frame.grid(row=2, column=0, columnspan=8, sticky="ew", padx=8, pady=(4, 4))
        self.auto_start_var = tk.BooleanVar(value=True)
        self.arm_only_var = tk.BooleanVar(value=False)
        self.reset_phase_var = tk.BooleanVar(value=True)
        auto_start_check = ttk.Checkbutton(
            flags_frame,
            text="AUTO_START (bit 0)",
            variable=self.auto_start_var,
            command=lambda: self.flags_changed("auto"),
        )
        auto_start_check.grid(row=0, column=0, sticky="w", padx=(0, 14))
        add_tooltip(
            auto_start_check,
            "After the samples are loaded into the selected channel memory, immediately start continuous playback of that channel.",
        )

        arm_only_check = ttk.Checkbutton(
            flags_frame,
            text="ARM_ONLY (bit 1)",
            variable=self.arm_only_var,
            command=lambda: self.flags_changed("arm"),
        )
        arm_only_check.grid(row=0, column=1, sticky="w", padx=(0, 14))
        add_tooltip(
            arm_only_check,
            "Load the samples and arm the channel without starting it. Start it later with a channel-mask command. AUTO_START and ARM_ONLY are mutually exclusive.",
        )

        reset_phase_check = ttk.Checkbutton(
            flags_frame,
            text="RESET_PHASE (bit 2)",
            variable=self.reset_phase_var,
            command=self.refresh_generated_waveform,
        )
        reset_phase_check.grid(row=0, column=2, sticky="w")
        add_tooltip(
            reset_phase_check,
            "Reset the channel read pointer to sample zero when this waveform is loaded, so playback begins at the start of the generated cycle.",
        )

        generator_buttons = ttk.Frame(waveform_box)
        generator_buttons.grid(row=3, column=0, columnspan=8, sticky="ew", padx=8, pady=(4, 8))
        generator_buttons.columnconfigure(5, weight=1)
        generate_button = ttk.Button(
            generator_buttons,
            text="Generate / refresh",
            command=lambda: self.refresh_generated_waveform(show_error=True),
        )
        generate_button.grid(row=0, column=0, padx=(0, 6))
        add_tooltip(
            generate_button,
            "Generate one waveform cycle, convert voltages to 16-bit DAC codes, calculate SAMPLE_PERIOD_TICKS, and update the plot and previews.",
        )

        send_waveform_button = ttk.Button(
            generator_buttons,
            text="Send waveform to FPGA",
            command=self.send_load,
        )
        send_waveform_button.grid(row=0, column=1, padx=(0, 6))
        add_tooltip(
            send_waveform_button,
            "Build the complete Ethernet telecommand and queue it for transmission to the selected physical DAC and channel.",
        )

        preview_button = ttk.Button(
            generator_buttons,
            text="Build packet preview",
            command=self.preview_load,
        )
        preview_button.grid(row=0, column=2, padx=(0, 6))
        add_tooltip(
            preview_button,
            "Build the exact packet without transmitting it. The preview includes VERSION, PACK_SEQ, SOURCE_ID, DATA_LENGTH, flags, timing, and samples.",
        )

        copy_hex_button = ttk.Button(
            generator_buttons,
            text="Copy packet HEX",
            command=self.copy_packet_hex,
        )
        copy_hex_button.grid(row=0, column=3, padx=(0, 6))
        add_tooltip(
            copy_hex_button,
            "Copy the complete generated Ethernet packet as hexadecimal text to the system clipboard.",
        )
        self.generator_summary_var = tk.StringVar(value="-")
        ttk.Label(generator_buttons, textvariable=self.generator_summary_var).grid(
            row=0, column=5, sticky="w"
        )

        preview_box = ttk.LabelFrame(self.frame, text="Generated cycle preview")
        preview_box.grid(row=3, column=0, sticky="nsew", pady=(0, 8))
        preview_box.columnconfigure(0, weight=1)
        preview_box.columnconfigure(1, weight=1)
        preview_box.rowconfigure(0, weight=1)

        sample_frame = ttk.Frame(preview_box)
        sample_frame.grid(row=0, column=0, sticky="nsew", padx=(8, 4), pady=8)
        sample_frame.columnconfigure(0, weight=1)
        sample_frame.rowconfigure(1, weight=1)
        ttk.Label(sample_frame, text="Generated 16-bit samples (HEX)").grid(
            row=0, column=0, sticky="w", pady=(0, 4)
        )
        self.samples_text = tk.Text(sample_frame, height=9, wrap="word", state="disabled")
        self.samples_text.grid(row=1, column=0, sticky="nsew")
        add_tooltip(
            self.samples_text,
            "Generated 16-bit DAC sample words for one cycle. Each word is transmitted most-significant byte first and stored in FPGA channel memory.",
        )
        sample_scroll = ttk.Scrollbar(sample_frame, orient="vertical", command=self.samples_text.yview)
        sample_scroll.grid(row=1, column=1, sticky="ns")
        self.samples_text.configure(yscrollcommand=sample_scroll.set)

        plot_frame = ttk.Frame(preview_box)
        plot_frame.grid(row=0, column=1, sticky="nsew", padx=(4, 8), pady=8)
        plot_frame.columnconfigure(0, weight=1)
        plot_frame.rowconfigure(0, weight=1)
        self.waveform_figure = None
        self.waveform_canvas = None
        if HAS_MATPLOTLIB:
            self.waveform_figure = Figure(figsize=(5.4, 2.5), dpi=100)
            self.waveform_canvas = FigureCanvasTkAgg(self.waveform_figure, master=plot_frame)
            self.waveform_canvas.get_tk_widget().grid(row=0, column=0, sticky="nsew")
        else:
            ttk.Label(
                plot_frame,
                text="Install matplotlib to display the waveform plot.",
            ).grid(row=0, column=0, sticky="nsew")

        packet_box = ttk.LabelFrame(self.frame, text="Complete Ethernet telecommand packet")
        packet_box.grid(row=4, column=0, sticky="ew", pady=(0, 8))
        packet_box.columnconfigure(0, weight=1)
        self.packet_preview_text = tk.Text(packet_box, height=4, wrap="word", state="disabled")
        self.packet_preview_text.grid(row=0, column=0, sticky="ew", padx=(8, 0), pady=8)
        add_tooltip(
            self.packet_preview_text,
            "Complete packet sent to the board: VERSION | PACK_SEQ | SOURCE_ID | DATA_LENGTH | DATA.",
        )
        packet_scroll = ttk.Scrollbar(packet_box, orient="vertical", command=self.packet_preview_text.yview)
        packet_scroll.grid(row=0, column=1, sticky="ns", padx=(0, 8), pady=8)
        self.packet_preview_text.configure(yscrollcommand=packet_scroll.set)

        control_box = ttk.LabelFrame(self.frame, text="Start and stop controls")
        control_box.grid(row=5, column=0, sticky="ew", pady=(0, 8))
        control_box.columnconfigure(12, weight=1)

        stop_selected_button = ttk.Button(
            control_box,
            text="Stop/zero selected channel",
            command=self.send_stop_channel,
        )
        stop_selected_button.grid(row=0, column=0, padx=8, pady=8)
        add_tooltip(
            stop_selected_button,
            "Send command 0x08..0x0F for the selected channel. Playback stops and the channel output is driven to zero scale.",
        )

        ttk.Label(control_box, text="Channel mask").grid(
            row=0, column=1, sticky="e", padx=(8, 4), pady=8
        )
        self.mask_vars = [tk.BooleanVar(value=False) for _ in DAC_CHANNELS]
        for idx, (channel, var) in enumerate(zip(DAC_CHANNELS, self.mask_vars)):
            mask_check = ttk.Checkbutton(
                control_box,
                text=channel,
                variable=var,
                command=self.update_control_preview,
            )
            mask_check.grid(row=0, column=2 + idx, padx=2, pady=8)
            add_tooltip(
                mask_check,
                f"Include channel {channel} in the 8-bit start/stop mask. Bit {idx} controls channel {channel}.",
            )

        start_mask_button = ttk.Button(control_box, text="Start mask", command=self.send_start_mask)
        start_mask_button.grid(row=1, column=0, padx=8, pady=(0, 8))
        add_tooltip(
            start_mask_button,
            "Send command 0x10 followed by the selected 8-bit channel mask. All selected channels start together.",
        )

        stop_mask_button = ttk.Button(control_box, text="Stop/zero mask", command=self.send_stop_mask)
        stop_mask_button.grid(row=1, column=1, padx=(0, 6), pady=(0, 8))
        add_tooltip(
            stop_mask_button,
            "Send command 0x11 followed by the selected 8-bit channel mask. All selected channels stop and go to zero scale.",
        )

        select_all_button = ttk.Button(control_box, text="Select all", command=self.select_all_mask)
        select_all_button.grid(row=1, column=2, columnspan=2, padx=(0, 6), pady=(0, 8))
        add_tooltip(select_all_button, "Enable all eight channel-mask bits A..H.")

        clear_mask_button = ttk.Button(control_box, text="Clear mask", command=self.clear_mask)
        clear_mask_button.grid(row=1, column=4, columnspan=2, padx=(0, 6), pady=(0, 8))
        add_tooltip(clear_mask_button, "Clear all channel-mask bits.")
        self.control_preview_var = tk.StringVar(value="Control TX preview: -")
        ttk.Label(
            control_box,
            textvariable=self.control_preview_var,
            wraplength=820,
            justify="left",
        ).grid(row=1, column=6, columnspan=7, sticky="w", padx=8, pady=(0, 8))

        format_box = ttk.LabelFrame(self.frame, text="HDL payload format")
        format_box.grid(row=6, column=0, sticky="ew", pady=(0, 8))
        ttk.Label(
            format_box,
            text=(
                "Load: DATA[0]=00..07, DATA[1]=FLAGS, DATA[2:5]=SAMPLE_PERIOD_TICKS "
                "big-endian, DATA[6:]=16-bit samples big-endian. The GUI stores exactly "
                "one generated cycle; the FPGA repeats that memory continuously."
            ),
            wraplength=1160,
            justify="left",
        ).grid(row=0, column=0, sticky="w", padx=8, pady=8)

        rx_box = ttk.LabelFrame(self.frame, text="Received / echo / telemetry")
        rx_box.grid(row=7, column=0, sticky="nsew")
        rx_box.columnconfigure(0, weight=1)
        rx_box.rowconfigure(0, weight=1)
        self.rx_text = tk.Text(rx_box, height=7, wrap="word", state="disabled")
        self.rx_text.grid(row=0, column=0, sticky="nsew", padx=(6, 0), pady=6)
        scrollbar = ttk.Scrollbar(rx_box, orient="vertical", command=self.rx_text.yview)
        scrollbar.grid(row=0, column=1, sticky="ns", padx=(0, 6), pady=6)
        self.rx_text.configure(yscrollcommand=scrollbar.set)

        clear_rx_button = ttk.Button(self.frame, text="Clear received box", command=self.clear_rx)
        clear_rx_button.grid(row=8, column=0, sticky="e", pady=(8, 0))
        add_tooltip(clear_rx_button, "Remove all displayed DAC echo and telemetry log lines.")

        self.waveform_type_changed()
        self.refresh_generated_waveform(show_error=False)
        self.update_control_preview()

    def selected_source(self) -> int:
        return DAC_SOURCES[self.dac_var.get()]

    def selected_channel_index(self) -> int:
        channel = self.channel_var.get().strip().upper()
        if channel not in DAC_CHANNELS:
            raise ValueError("DAC channel must be A through H.")
        return DAC_CHANNELS.index(channel)

    def parse_positive_float(self, variable: tk.StringVar, field_name: str) -> float:
        try:
            value = float(variable.get().strip())
        except ValueError as exc:
            raise ValueError(f"{field_name} must be a number.") from exc
        if value <= 0.0:
            raise ValueError(f"{field_name} must be greater than zero.")
        return value

    def parse_nonnegative_float(self, variable: tk.StringVar, field_name: str) -> float:
        try:
            value = float(variable.get().strip())
        except ValueError as exc:
            raise ValueError(f"{field_name} must be a number.") from exc
        if value < 0.0:
            raise ValueError(f"{field_name} cannot be negative.")
        return value

    def parse_sample_count(self) -> int:
        try:
            value = int(self.sample_count_var.get().strip(), 10)
        except ValueError as exc:
            raise ValueError("Samples/cycle must be an integer.") from exc
        if not 1 <= value <= DAC_MAX_SAMPLES:
            raise ValueError(f"Samples/cycle must be 1..{DAC_MAX_SAMPLES}.")
        return value

    def parse_duty_percent(self) -> float:
        try:
            value = float(self.duty_var.get().strip())
        except ValueError as exc:
            raise ValueError("Pulse duty cycle must be a number.") from exc
        if not 0.0 < value < 100.0:
            raise ValueError("Pulse duty cycle must be greater than 0 and less than 100 percent.")
        return value

    def flags_byte(self) -> int:
        if self.auto_start_var.get() and self.arm_only_var.get():
            raise ValueError("AUTO_START and ARM_ONLY cannot both be enabled.")
        value = 0
        if self.auto_start_var.get():
            value |= 0x01
        if self.arm_only_var.get():
            value |= 0x02
        if self.reset_phase_var.get():
            value |= 0x04
        return value

    def flags_changed(self, changed: str):
        if self.auto_start_var.get() and self.arm_only_var.get():
            if changed == "auto":
                self.arm_only_var.set(False)
            else:
                self.auto_start_var.set(False)
        self.refresh_generated_waveform(show_error=False)

    def waveform_type_changed(self, _event=None):
        state = "normal" if self.waveform_var.get() == "Pulse" else "disabled"
        self.duty_entry.configure(state=state)
        self.refresh_generated_waveform(show_error=False)

    def calculate_current_waveform(self) -> tuple[list[int], list[float], int, float, float]:
        waveform = self.waveform_var.get().strip()
        frequency_hz = self.parse_positive_float(self.frequency_var, "Frequency")
        maximum_amplitude = self.parse_nonnegative_float(
            self.amplitude_var, "Maximum amplitude"
        )
        full_scale = self.parse_positive_float(self.full_scale_var, "DAC full scale")
        sample_count = self.parse_sample_count()
        fpga_clock_hz = self.parse_positive_float(self.fpga_clock_var, "FPGA clock")
        duty_percent = (
            self.parse_duty_percent() if waveform == "Pulse" else 50.0
        )

        samples, voltages = generate_dac_waveform_samples(
            waveform=waveform,
            sample_count=sample_count,
            maximum_amplitude_volts=maximum_amplitude,
            full_scale_volts=full_scale,
            pulse_duty_percent=duty_percent,
        )
        period_ticks, achieved_frequency_hz, sample_rate_hz = calculate_dac_period_ticks(
            fpga_clock_hz=fpga_clock_hz,
            frequency_hz=frequency_hz,
            sample_count=sample_count,
        )
        return samples, voltages, period_ticks, achieved_frequency_hz, sample_rate_hz

    def refresh_generated_waveform(self, show_error: bool = False):
        source = DAC_SOURCES.get(self.dac_var.get(), 0)
        channel = self.channel_var.get().strip().upper() or "?"
        self.source_hint_var.set(
            f"SOURCE_ID=0x{source:02X} | selected channel={channel}"
        )
        try:
            (
                self.generated_samples,
                self.generated_voltages,
                self.generated_period_ticks,
                self.generated_frequency_hz,
                self.generated_sample_rate_hz,
            ) = self.calculate_current_waveform()

            self.update_samples_text()
            packet, flags, period, sample_count = self.build_load_packet(use_cached=True)
            self.update_packet_preview(packet)
            requested_frequency = float(self.frequency_var.get().strip())
            frequency_error_ppm = (
                (self.generated_frequency_hz - requested_frequency)
                / requested_frequency
                * 1_000_000.0
            )
            maximum_code = max(self.generated_samples) if self.generated_samples else 0
            self.generator_summary_var.set(
                f"PERIOD=0x{period:08X} ({period} ticks) | "
                f"actual f={self.generated_frequency_hz:.9g} Hz | "
                f"error={frequency_error_ppm:+.3f} ppm | "
                f"sample rate={self.generated_sample_rate_hz:.9g} Sa/s | "
                f"samples={sample_count} | max code=0x{maximum_code:04X} | FLAGS=0x{flags:02X}"
            )
            self.redraw_waveform_plot()
        except Exception as exc:
            self.generated_samples = []
            self.generated_voltages = []
            self.generated_period_ticks = 0
            self.generator_summary_var.set(f"Invalid waveform settings: {exc}")
            self.update_samples_text()
            self.update_packet_preview(None, error=str(exc))
            self.redraw_waveform_plot(error=str(exc))
            if show_error:
                messagebox.showerror("DAC waveform error", str(exc))

    def update_samples_text(self):
        text = " ".join(f"{sample:04X}" for sample in self.generated_samples)
        self.samples_text.configure(state="normal")
        self.samples_text.delete("1.0", "end")
        self.samples_text.insert("1.0", text)
        self.samples_text.configure(state="disabled")

    def update_packet_preview(self, packet: bytes | None, error: str | None = None):
        self.packet_preview_text.configure(state="normal")
        self.packet_preview_text.delete("1.0", "end")
        if packet is not None:
            self.packet_preview_text.insert("1.0", bytes_to_hex(packet))
        else:
            self.packet_preview_text.insert("1.0", f"Invalid packet: {error or '-'}")
        self.packet_preview_text.configure(state="disabled")

    def redraw_waveform_plot(self, error: str | None = None):
        if self.waveform_figure is None or self.waveform_canvas is None:
            return
        self.waveform_figure.clear()
        ax = self.waveform_figure.add_subplot(111)
        if error or not self.generated_voltages:
            ax.axis("off")
            ax.text(
                0.5,
                0.5,
                error or "No generated waveform",
                ha="center",
                va="center",
                transform=ax.transAxes,
                wrap=True,
            )
        else:
            fpga_clock_hz = float(self.fpga_clock_var.get().strip())
            sample_period_seconds = self.generated_period_ticks / fpga_clock_hz
            times = [index * sample_period_seconds for index in range(len(self.generated_voltages))]
            if times and times[-1] < 0.001:
                scale = 1_000_000.0
                xlabel = "Time (us)"
            elif times and times[-1] < 1.0:
                scale = 1_000.0
                xlabel = "Time (ms)"
            else:
                scale = 1.0
                xlabel = "Time (s)"
            ax.plot([value * scale for value in times], self.generated_voltages, marker=".")
            ax.set_title(
                f"{self.waveform_var.get()} | actual frequency {self.generated_frequency_hz:.9g} Hz"
            )
            ax.set_xlabel(xlabel)
            ax.set_ylabel("Output voltage (V)")
            full_scale = float(self.full_scale_var.get().strip())
            ax.set_ylim(0.0, full_scale)
            ax.grid(True)
        self.waveform_figure.tight_layout()
        self.waveform_canvas.draw_idle()

    def build_tc_packet(self, payload: bytes) -> bytes:
        length = tc_length_from_payload_size(len(payload))
        seq = self.app.pack_seq & 0xFF
        return bytes([VERSION, seq, self.selected_source(), length]) + payload

    def build_load_payload(self, use_cached: bool = False) -> tuple[bytes, int, int, int]:
        if not use_cached or not self.generated_samples or self.generated_period_ticks == 0:
            (
                self.generated_samples,
                self.generated_voltages,
                self.generated_period_ticks,
                self.generated_frequency_hz,
                self.generated_sample_rate_hz,
            ) = self.calculate_current_waveform()

        channel_index = self.selected_channel_index()
        flags = self.flags_byte()
        period = self.generated_period_ticks
        samples = self.generated_samples
        payload = bytearray([channel_index, flags])
        payload.extend(period.to_bytes(4, byteorder="big", signed=False))
        for sample in samples:
            payload.extend(sample.to_bytes(2, byteorder="big", signed=False))
        if len(payload) > 256:
            raise ValueError("DATA payload exceeds the 256-byte command limit.")
        return bytes(payload), flags, period, len(samples)

    def build_load_packet(self, use_cached: bool = False) -> tuple[bytes, int, int, int]:
        payload, flags, period, sample_count = self.build_load_payload(use_cached=use_cached)
        return self.build_tc_packet(payload), flags, period, sample_count

    def preview_load(self):
        try:
            self.refresh_generated_waveform(show_error=True)
            packet, _flags, _period, _sample_count = self.build_load_packet(use_cached=True)
            self.update_packet_preview(packet)
        except Exception as exc:
            messagebox.showerror("DAC packet error", str(exc))

    def send_load(self):
        try:
            self.refresh_generated_waveform(show_error=True)
            if not self.generated_samples:
                return
            packet, _flags, _period, sample_count = self.build_load_packet(use_cached=True)
            self.app.queue_packet_for_send(
                packet,
                f"DAC/{self.dac_var.get()}/{self.channel_var.get()}/{self.waveform_var.get()}",
            )
            self.update_packet_preview(packet)
            self.generator_summary_var.set(
                self.generator_summary_var.get()
                + f" | queued {sample_count} samples"
            )
        except Exception as exc:
            messagebox.showerror("DAC waveform send error", str(exc))

    def copy_packet_hex(self):
        try:
            self.refresh_generated_waveform(show_error=True)
            if not self.generated_samples:
                return
            packet, _flags, _period, _sample_count = self.build_load_packet(use_cached=True)
            self.frame.clipboard_clear()
            self.frame.clipboard_append(bytes_to_hex(packet))
            self.frame.update()
        except Exception as exc:
            messagebox.showerror("Copy packet error", str(exc))

    def mask_byte(self) -> int:
        value = 0
        for idx, var in enumerate(self.mask_vars):
            if var.get():
                value |= 1 << idx
        return value

    def build_stop_channel_packet(self) -> bytes:
        command = 0x08 + self.selected_channel_index()
        return self.build_tc_packet(bytes([command]))

    def build_mask_packet(self, command: int) -> bytes:
        mask = self.mask_byte()
        if mask == 0:
            raise ValueError("Select at least one channel in the mask.")
        return self.build_tc_packet(bytes([command, mask]))

    def update_control_preview(self):
        try:
            stop_channel = bytes_to_hex(self.build_stop_channel_packet())
            mask = self.mask_byte()
            start_mask = bytes_to_hex(self.build_tc_packet(bytes([0x10, mask])))
            stop_mask = bytes_to_hex(self.build_tc_packet(bytes([0x11, mask])))
            self.control_preview_var.set(
                f"Stop channel: {stop_channel} | Start mask: {start_mask} | "
                f"Stop mask: {stop_mask}"
            )
        except Exception as exc:
            self.control_preview_var.set(f"Control TX preview: invalid ({exc})")

    def send_stop_channel(self):
        try:
            packet = self.build_stop_channel_packet()
            self.app.queue_packet_for_send(
                packet, f"DAC/{self.dac_var.get()}/stop-channel"
            )
            self.control_preview_var.set(f"Sent/queued stop channel: {bytes_to_hex(packet)}")
        except Exception as exc:
            messagebox.showerror("DAC stop-channel error", str(exc))

    def send_start_mask(self):
        try:
            packet = self.build_mask_packet(0x10)
            self.app.queue_packet_for_send(packet, f"DAC/{self.dac_var.get()}/start-mask")
            self.control_preview_var.set(f"Sent/queued start mask: {bytes_to_hex(packet)}")
        except Exception as exc:
            messagebox.showerror("DAC start-mask error", str(exc))

    def send_stop_mask(self):
        try:
            packet = self.build_mask_packet(0x11)
            self.app.queue_packet_for_send(packet, f"DAC/{self.dac_var.get()}/stop-mask")
            self.control_preview_var.set(f"Sent/queued stop mask: {bytes_to_hex(packet)}")
        except Exception as exc:
            messagebox.showerror("DAC stop-mask error", str(exc))

    def select_all_mask(self):
        for var in self.mask_vars:
            var.set(True)
        self.update_control_preview()

    def clear_mask(self):
        for var in self.mask_vars:
            var.set(False)
        self.update_control_preview()

    def append_rx(self, line: str):
        self.pending_log.append(line)

    def clear_rx(self):
        self.rx_text.configure(state="normal")
        self.rx_text.delete("1.0", "end")
        self.rx_text.configure(state="disabled")
        self.pending_log.clear()

    def flush_pending_logs(self):
        if not self.pending_log:
            return
        lines = self.pending_log[:MAX_LOG_LINES_PER_FLUSH]
        del self.pending_log[:MAX_LOG_LINES_PER_FLUSH]
        self.rx_text.configure(state="normal")
        for line in lines:
            self.rx_text.insert("end", line + "\n")
        self.trim_text_widget()
        self.rx_text.see("end")
        self.rx_text.configure(state="disabled")

    def trim_text_widget(self):
        try:
            line_count = int(self.rx_text.index("end-1c").split(".")[0])
            if line_count > MAX_LOG_LINES_PER_BOX:
                delete_to = line_count - MAX_LOG_LINES_PER_BOX + 1
                self.rx_text.delete("1.0", f"{delete_to}.0")
        except Exception:
            pass

class AdcChannelSubTab:
    def __init__(self, app, notebook: ttk.Notebook, adc_name: str, source_id: int):
        self.app = app
        self.adc_name = adc_name
        self.source_id = source_id
        self.pending_log = []
        self.channel_vars = [tk.BooleanVar(value=False) for _ in ADC_PAIR_LABELS]
        self.series = {ch: {"x": deque(maxlen=ADC_MAX_PLOT_POINTS), "frame": deque(maxlen=ADC_MAX_PLOT_POINTS), "y": deque(maxlen=ADC_MAX_PLOT_POINTS)} for ch in range(1, 13)}
        self.channel_sample_counts = {ch: 0 for ch in range(1, 13)}
        self.telemetry_frames = 0
        self.last_tel_seq = 0
        self.last_time = 0
        self.last_unwrapped_time = 0
        self.timestamp_wrap_offset = 0
        self.previous_raw_timestamp = None
        self.frame_period_estimate_seconds = None
        self.last_samples_text = "-"
        self.plot_dirty = False
        self.plot_window = None
        self.plot_figure = None
        self.plot_canvas = None
        self.plot_toolbar = None
        self.plot_axes_channel_map = {}
        self.grid_view_locked = False
        self.grid_view_limits = {}
        self.single_plot_windows = {}
        self.frame = ttk.Frame(notebook, padding=10)
        notebook.add(self.frame, text=adc_name)
        self.frame.columnconfigure(0, weight=1)
        self.frame.rowconfigure(5, weight=1)
        header = ttk.Frame(self.frame)
        header.grid(row=0, column=0, sticky="ew")
        header.columnconfigure(1, weight=1)
        ttk.Label(header, text=f"{adc_name} command + telemetry").grid(row=0, column=0, sticky="w")
        self.header_var = tk.StringVar()
        ttk.Label(header, textvariable=self.header_var).grid(row=0, column=1, sticky="w", padx=(12, 0))
        pair_box = ttk.LabelFrame(self.frame, text="ADC channel-pair enable mask")
        pair_box.grid(row=1, column=0, sticky="ew", pady=(8, 8))
        for col in range(3):
            pair_box.columnconfigure(col, weight=1)
        for idx, ((pair_name, channel_label), var) in enumerate(zip(ADC_PAIR_LABELS, self.channel_vars)):
            cb = ttk.Checkbutton(pair_box, text=f"{pair_name}: {channel_label}", variable=var, command=self.update_preview)
            cb.grid(row=idx // 3, column=idx % 3, sticky="w", padx=8, pady=8)
        buttons = ttk.Frame(self.frame)
        buttons.grid(row=2, column=0, sticky="ew", pady=(0, 8))
        buttons.columnconfigure(10, weight=1)
        ttk.Button(buttons, text="Send command", command=self.send_clicked).grid(row=0, column=0, padx=(0, 6))
        ttk.Button(buttons, text="Activate all", command=self.activate_all).grid(row=0, column=1, padx=(0, 6))
        ttk.Button(buttons, text="Deactivate all", command=self.deactivate_all).grid(row=0, column=2, padx=(0, 6))
        ttk.Button(buttons, text="Open plot window", command=self.open_plot_window).grid(row=0, column=3, padx=(0, 6))
        ttk.Button(buttons, text="Clear plots", command=self.clear_plot).grid(row=0, column=4, padx=(0, 6))
        ttk.Label(buttons, text="Single plot:").grid(row=0, column=5, sticky="e", padx=(10, 4))
        self.single_channel_var = tk.StringVar(value="")
        self.single_channel_combo = ttk.Combobox(buttons, textvariable=self.single_channel_var, values=[], state="disabled", width=7)
        self.single_channel_combo.grid(row=0, column=6, padx=(0, 6))
        ttk.Button(buttons, text="Open selected", command=self.open_selected_single_plot).grid(row=0, column=7, padx=(0, 6))
        self.preview_var = tk.StringVar(value="TX preview: -")
        ttk.Label(buttons, textvariable=self.preview_var).grid(row=0, column=10, sticky="w")
        status_box = ttk.LabelFrame(self.frame, text="Telemetry status")
        status_box.grid(row=3, column=0, sticky="ew", pady=(0, 8))
        status_box.columnconfigure(0, weight=1)
        self.tm_status_var = tk.StringVar(value="No telemetry yet.")
        ttk.Label(status_box, textvariable=self.tm_status_var).grid(row=0, column=0, sticky="w", padx=8, pady=8)
        hint_box = ttk.LabelFrame(self.frame, text="Plot update")
        hint_box.grid(row=4, column=0, sticky="ew", pady=(0, 8))
        hint_box.columnconfigure(0, weight=1)
        self.plot_hint_var = tk.StringVar(value="Plots are updated at a throttled rate to keep the GUI responsive.")
        ttk.Label(hint_box, textvariable=self.plot_hint_var).grid(row=0, column=0, sticky="w", padx=8, pady=8)
        rx_box = ttk.LabelFrame(self.frame, text="Received / echo / telemetry decode")
        rx_box.grid(row=5, column=0, sticky="nsew")
        rx_box.columnconfigure(0, weight=1)
        rx_box.rowconfigure(0, weight=1)
        self.rx_text = tk.Text(rx_box, height=12, wrap="word", state="disabled")
        self.rx_text.grid(row=0, column=0, sticky="nsew", padx=(6, 0), pady=6)
        scrollbar = ttk.Scrollbar(rx_box, orient="vertical", command=self.rx_text.yview)
        scrollbar.grid(row=0, column=1, sticky="ns", padx=(0, 6), pady=6)
        self.rx_text.configure(yscrollcommand=scrollbar.set)
        ttk.Button(self.frame, text="Clear received box", command=self.clear_rx).grid(row=6, column=0, sticky="e", pady=(8, 0))
        self.update_preview()

    def selected_bits_string(self) -> str:
        return "".join("1" if var.get() else "0" for var in self.channel_vars)

    def selected_channel_numbers(self) -> list[int]:
        channels = []
        for pair_channels, var in zip(ADC_PAIR_CHANNELS, self.channel_vars):
            if var.get():
                channels.extend(pair_channels)
        return channels

    def data_byte(self) -> int:
        return int(self.selected_bits_string() + "00", 2)

    def build_packet(self) -> bytes:
        data = bytes([self.data_byte()])
        seq = self.app.pack_seq & 0xFF
        return bytes([VERSION, seq, self.source_id, tc_length_from_payload_size(len(data))]) + data

    def update_preview(self):
        bits = self.selected_bits_string()
        active_channels = self.selected_channel_numbers()
        active = ", ".join(adc_channel_name(ch) for ch in active_channels) or "none"
        self.header_var.set(f"Source=0x{self.source_id:02X} ({self.adc_name}) | DATA={bits}00b=0x{self.data_byte():02X} | active={active}")
        self.update_single_channel_combo(active_channels)
        self.preview_var.set(f"TX preview: {bytes_to_hex(self.build_packet())}")
        self.update_plot_hint()

    def update_single_channel_combo(self, active_channels: list[int]):
        values = [adc_channel_name(ch) for ch in active_channels]
        self.single_channel_combo.configure(values=values)
        current = self.single_channel_var.get()
        if current not in values:
            self.single_channel_var.set(values[0] if values else "")
        self.single_channel_combo.configure(state="readonly" if values else "disabled")

    def send_clicked(self):
        try:
            pkt = self.build_packet()
            self.app.set_adc_active_channels(self.source_id, self.selected_channel_numbers())
            self.app.queue_packet_for_send(pkt, f"ADC/{self.adc_name}")
            self.preview_var.set(f"Sent/queued: {bytes_to_hex(pkt)}")
        except Exception as exc:
            messagebox.showerror("ADC send error", str(exc))

    def activate_all(self):
        for var in self.channel_vars:
            var.set(True)
        self.update_preview()

    def deactivate_all(self):
        for var in self.channel_vars:
            var.set(False)
        self.update_preview()

    def unwrap_timestamp(self, raw_timestamp: int) -> int:
        raw_timestamp &= FPGA_TIMESTAMP_MODULUS - 1
        if self.previous_raw_timestamp is not None:
            backward_jump = self.previous_raw_timestamp - raw_timestamp
            if raw_timestamp < self.previous_raw_timestamp and backward_jump > (FPGA_TIMESTAMP_MODULUS // 2):
                self.timestamp_wrap_offset += FPGA_TIMESTAMP_MODULUS
        self.previous_raw_timestamp = raw_timestamp
        return self.timestamp_wrap_offset + raw_timestamp

    def interpolate_frame_time_axis(self, raw_times: list[float], frame_numbers: list[int]) -> list[float]:
        """Reconstruct a clean sample-time axis from telemetry-frame timestamps.

        The timestamp field is intentionally retained as the time reference, but
        its resolution is much coarser than the ADC telemetry rate.  Plotting the
        raw staircase timestamps directly creates vertical clusters and long
        diagonal joins.  This routine therefore estimates one seconds-per-frame
        value from all timestamp transitions and uses the telemetry-frame order
        to place every received sample uniformly between those time anchors.

        The result is still expressed in FPGA telemetry seconds; sample index is
        never used as the displayed x-axis quantity.
        """
        count = min(len(raw_times), len(frame_numbers))
        if count == 0:
            return []

        times = [float(value) for value in raw_times[:count]]
        frames_in = [int(value) for value in frame_numbers[:count]]
        if count == 1:
            return [times[0]]

        # Preserve acquisition order even if a duplicated/out-of-order frame
        # identifier is observed after UDP delivery.
        frames: list[int] = []
        previous_frame = None
        for index, frame in enumerate(frames_in):
            if previous_frame is None:
                clean_frame = frame
            elif frame > previous_frame:
                clean_frame = frame
            else:
                clean_frame = previous_frame + 1
            frames.append(clean_frame)
            previous_frame = clean_frame

        # Collapse each contiguous timestamp plateau to its centre frame.  The
        # plateau centres are the reliable time anchors for the linear fit.
        groups: list[tuple[float, float]] = []
        group_start = 0
        for index in range(1, count):
            if times[index] != times[group_start]:
                centre_frame = 0.5 * (frames[group_start] + frames[index - 1])
                groups.append((centre_frame, times[group_start]))
                group_start = index
        centre_frame = 0.5 * (frames[group_start] + frames[count - 1])
        groups.append((centre_frame, times[group_start]))

        period = None
        if len(groups) >= 2:
            mean_frame = sum(item[0] for item in groups) / len(groups)
            mean_time = sum(item[1] for item in groups) / len(groups)
            denominator = sum((item[0] - mean_frame) ** 2 for item in groups)
            if denominator > 0.0:
                candidate = sum(
                    (item[0] - mean_frame) * (item[1] - mean_time)
                    for item in groups
                ) / denominator
                if candidate > 0.0 and math.isfinite(candidate):
                    period = candidate

            # Endpoint fallback protects against an ill-conditioned short fit.
            if period is None:
                frame_span = groups[-1][0] - groups[0][0]
                time_span = groups[-1][1] - groups[0][1]
                if frame_span > 0.0 and time_span > 0.0:
                    period = time_span / frame_span

        if period is not None:
            self.frame_period_estimate_seconds = period
        elif self.frame_period_estimate_seconds is not None:
            period = self.frame_period_estimate_seconds
        else:
            # Startup fallback used only before the first timestamp transition.
            tick_seconds = max(self.app.get_fpga_timestamp_tick_seconds(), 1e-12)
            frame_span = max(frames[-1] - frames[0] + 1, 1)
            period = tick_seconds / frame_span

        # Anchor the uniform frame-time mapping to the newest timestamp plateau.
        anchor_frame, anchor_time = groups[-1]
        result = [
            anchor_time + ((frame - anchor_frame) * period)
            for frame in frames
        ]

        # Numerical guard only; normal operation is already strictly monotonic.
        minimum_step = max(period * 1e-6, 1e-12)
        for index in range(1, count):
            if result[index] <= result[index - 1]:
                result[index] = result[index - 1] + minimum_step
        return result

    def receive_telemetry(self, packet: bytes, meta: dict, payload: bytes):
        decoded, warning = decode_adc_payload_triples(payload)
        self.telemetry_frames += 1
        self.last_tel_seq = meta.get("tel_seq", 0)
        self.last_time = meta.get("time", 0) & (FPGA_TIMESTAMP_MODULUS - 1)
        self.last_unwrapped_time = self.unwrap_timestamp(self.last_time)
        time_seconds = self.last_unwrapped_time * self.app.get_fpga_timestamp_tick_seconds()

        parts = []
        for ch, sample, raw in decoded:
            voltage = self.app.adc_code_to_voltage(sample)
            parts.append(
                f"{adc_channel_name(ch)}=0x{sample:03X} ({sample}) = {voltage:.6f} V"
            )
            if ch in self.series:
                # Use the unwrapped FPGA timestamp carried by the telemetry frame
                # as the x coordinate for every received ADC value. Multiple samples
                # may legitimately share one timestamp when the FPGA timer resolution
                # is coarser than the ADC telemetry rate.
                self.channel_sample_counts[ch] += 1
                self.series[ch]["x"].append(time_seconds)
                self.series[ch]["frame"].append(self.telemetry_frames)
                self.series[ch]["y"].append(sample)

        self.last_samples_text = ", ".join(parts) if parts else "-"
        extra_warning = f" | WARNING: {warning}" if warning else ""
        self.tm_status_var.set(
            f"Frames={self.telemetry_frames} | TEL_SEQ=0x{self.last_tel_seq:02X} | "
            f"TIME=0x{self.last_time:04X} = {time_seconds:.3f} s | "
            f"{self.last_samples_text}{extra_warning}"
        )
        self.plot_dirty = True
        if self.app.log_telemetry_var.get():
            line = (
                f"[{now_stamp()}] RX telemetry | TEL_SEQ=0x{self.last_tel_seq:02X}, "
                f"TIME=0x{self.last_time:04X} ({time_seconds:.3f} s), "
                f"SOURCE=0x{self.source_id:02X}, RAW={bytes_to_hex(packet)} | "
                f"{self.last_samples_text}{extra_warning}"
            )
            self.append_rx(line)
        elif self.telemetry_frames == 1 or (self.telemetry_frames % ADC_SUMMARY_INTERVAL) == 0:
            self.append_rx(
                f"[{now_stamp()}] telemetry summary #{self.telemetry_frames} | "
                f"TEL_SEQ=0x{self.last_tel_seq:02X}, TIME={time_seconds:.3f} s | "
                f"{self.last_samples_text}"
            )

    def receive_echo(self, line: str):
        self.append_rx(line)

    def append_rx(self, line: str):
        self.pending_log.append(line)

    def clear_rx(self):
        self.rx_text.configure(state="normal")
        self.rx_text.delete("1.0", "end")
        self.rx_text.configure(state="disabled")
        self.pending_log.clear()

    def flush_pending_logs(self):
        if not self.pending_log:
            return
        lines = self.pending_log[:MAX_LOG_LINES_PER_FLUSH]
        del self.pending_log[:MAX_LOG_LINES_PER_FLUSH]
        self.rx_text.configure(state="normal")
        for line in lines:
            self.rx_text.insert("end", line + "\n")
        self.trim_text_widget()
        self.rx_text.see("end")
        self.rx_text.configure(state="disabled")

    def trim_text_widget(self):
        try:
            line_count = int(self.rx_text.index("end-1c").split(".")[0])
            if line_count > MAX_LOG_LINES_PER_BOX:
                delete_to = line_count - MAX_LOG_LINES_PER_BOX + 1
                self.rx_text.delete("1.0", f"{delete_to}.0")
        except Exception:
            pass

    def clear_plot(self):
        for ch in self.series:
            self.series[ch]["x"].clear()
            self.series[ch]["frame"].clear()
            self.series[ch]["y"].clear()
        self.timestamp_wrap_offset = 0
        self.previous_raw_timestamp = None
        self.last_unwrapped_time = 0
        self.plot_dirty = True
        self.redraw_plot(force=True)

    def visible_channels_for_plot(self) -> list[int]:
        active = self.selected_channel_numbers()
        if active:
            return active
        return [ch for ch in sorted(self.series) if self.series[ch]["x"]]

    def active_grid_shape(self, n_axes: int) -> tuple[int, int]:
        if n_axes <= 1:
            return 1, 1
        if n_axes == 2:
            return 1, 2
        if n_axes <= 4:
            return 2, 2
        if n_axes <= 6:
            return 2, 3
        if n_axes <= 9:
            return 3, 3
        return 3, 4

    def open_plot_window(self):
        if not HAS_MATPLOTLIB:
            messagebox.showerror("matplotlib missing", "Install matplotlib first: python -m pip install matplotlib")
            return
        if self.plot_window is not None and self.plot_window.winfo_exists():
            self.plot_window.lift()
            self.plot_window.focus_force()
            self.redraw_plot(force=True)
            return
        self.plot_window = tk.Toplevel(self.frame)
        self.plot_window.title(f"{self.adc_name} ADC telemetry plots")
        self.plot_window.geometry("1180x760")
        self.plot_window.columnconfigure(0, weight=1)
        self.plot_window.rowconfigure(1, weight=1)
        self.plot_window.protocol("WM_DELETE_WINDOW", self.close_plot_window)
        top = ttk.Frame(self.plot_window, padding=(8, 8, 8, 4))
        top.grid(row=0, column=0, sticky="ew")
        top.columnconfigure(1, weight=1)
        ttk.Label(top, text=f"{self.adc_name}: active ADC channels").grid(row=0, column=0, sticky="w")
        ttk.Label(
            top,
            text="Box zoom: click the button, then drag a rectangle over the desired area.",
        ).grid(row=0, column=1, sticky="w", padx=(12, 0))
        ttk.Button(top, text="Box zoom", command=self.activate_grid_box_zoom).grid(row=0, column=2, padx=(8, 0))
        ttk.Button(top, text="Fit all / Live", command=self.reset_grid_view).grid(row=0, column=3, padx=(8, 0))
        ttk.Button(top, text="Refresh", command=lambda: self.redraw_plot(force=True)).grid(row=0, column=4, padx=(8, 0))
        ttk.Button(top, text="Close", command=self.close_plot_window).grid(row=0, column=5, padx=(8, 0))
        canvas_frame = ttk.Frame(self.plot_window, padding=(8, 0, 8, 8))
        canvas_frame.grid(row=1, column=0, sticky="nsew")
        canvas_frame.columnconfigure(0, weight=1)
        canvas_frame.rowconfigure(0, weight=1)
        self.plot_figure = Figure(figsize=(11.2, 6.6), dpi=100)
        self.plot_canvas = FigureCanvasTkAgg(self.plot_figure, master=canvas_frame)
        self.plot_canvas.get_tk_widget().grid(row=0, column=0, sticky="nsew")
        self.plot_toolbar = NavigationToolbar2Tk(self.plot_canvas, canvas_frame, pack_toolbar=False)
        self.plot_toolbar.update()
        self.plot_toolbar.grid(row=1, column=0, sticky="ew")
        self.plot_canvas.mpl_connect("button_press_event", self.on_grid_plot_click)
        self.plot_canvas.mpl_connect("button_release_event", self.on_grid_zoom_release)
        self.plot_canvas.mpl_connect("scroll_event", self.on_scroll_zoom)
        self.redraw_plot(force=True)

    def close_plot_window(self):
        if self.plot_window is not None and self.plot_window.winfo_exists():
            self.plot_window.destroy()
        self.plot_window = None
        self.plot_figure = None
        self.plot_canvas = None
        self.plot_toolbar = None
        self.plot_axes_channel_map = {}
        self.grid_view_locked = False
        self.grid_view_limits = {}

    def capture_grid_view_limits(self):
        if not self.grid_view_locked:
            return
        captured = {}
        for axis, channel in self.plot_axes_channel_map.items():
            try:
                captured[channel] = (axis.get_xlim(), axis.get_ylim())
            except Exception:
                continue
        if captured:
            self.grid_view_limits = captured

    def activate_grid_box_zoom(self):
        if self.plot_toolbar is None:
            return
        # NavigationToolbar2Tk.zoom() activates Matplotlib's rectangle selector.
        # The release callback below stores the chosen limits so live redraws
        # keep the selected box instead of returning to the complete history.
        self.plot_toolbar.zoom()

    def on_grid_zoom_release(self, event):
        if event.inaxes is None or self.plot_toolbar is None:
            return
        mode_text = str(getattr(self.plot_toolbar, "mode", "")).lower()
        if "zoom" not in mode_text:
            return
        self.grid_view_locked = True
        self.capture_grid_view_limits()

    def reset_grid_view(self):
        self.grid_view_locked = False
        self.grid_view_limits = {}
        if self.plot_toolbar is not None:
            mode_text = str(getattr(self.plot_toolbar, "mode", "")).lower()
            if "zoom" in mode_text:
                self.plot_toolbar.zoom()
        self.redraw_plot(force=True)

    def redraw_plot(self, force: bool = False):
        if not force and not self.plot_dirty:
            return
        self.plot_dirty = False
        self.update_plot_hint()
        self.redraw_grid_plot_window()
        self.redraw_single_plot_windows()

    def update_plot_hint(self):
        active = self.visible_channels_for_plot()
        if active:
            n_rows, n_cols = self.active_grid_shape(len(active))
            channels = ", ".join(adc_channel_name(ch) for ch in active)
            self.plot_hint_var.set(
                f"Visible channels: {channels}. Layout {n_rows} x {n_cols}. "
                f"The x-axis spans the complete retained FPGA-time history and expands as new values arrive. "
                f"Older values are compacted with a min/max-preserving method; displayed values remain actual received samples."
            )
        else:
            self.plot_hint_var.set("No samples yet. Send ADC command and wait for telemetry.")

    def redraw_grid_plot_window(self):
        if not HAS_MATPLOTLIB or self.plot_window is None or not self.plot_window.winfo_exists():
            return
        if self.plot_figure is None or self.plot_canvas is None:
            return
        visible_channels = self.visible_channels_for_plot()
        self.capture_grid_view_limits()
        self.plot_figure.clear()
        self.plot_axes_channel_map = {}
        if not visible_channels:
            ax = self.plot_figure.add_subplot(111)
            ax.axis("off")
            ax.text(0.5, 0.5, "No ADC samples yet", ha="center", va="center", transform=ax.transAxes)
            self.plot_figure.tight_layout()
            self.plot_canvas.draw()
            return
        n_rows, n_cols = self.active_grid_shape(len(visible_channels))
        for idx, ch in enumerate(visible_channels, start=1):
            ax = self.plot_figure.add_subplot(n_rows, n_cols, idx)
            self.plot_axes_channel_map[ax] = ch
            self.draw_channel_on_axis(ax, ch, compact=True)
            if self.grid_view_locked and ch in self.grid_view_limits:
                x_limits, y_limits = self.grid_view_limits[ch]
                ax.set_xlim(*x_limits)
                ax.set_ylim(*y_limits)
        self.plot_figure.suptitle(f"{self.adc_name}: {len(visible_channels)} channel plot(s)", fontsize=11)
        self.plot_figure.tight_layout(rect=(0, 0, 1, 0.95))
        self.plot_canvas.draw()

    def compact_history_for_plot(
        self,
        raw_times: list[float],
        frame_numbers: list[int],
        adc_codes: list[int],
        point_limit: int,
    ) -> tuple[list[float], list[int], list[int]]:
        """Keep the complete time span while reducing rendering cost.

        When the history is larger than ``point_limit``, each chronological
        bucket contributes its real minimum and maximum ADC samples.  This
        preserves peaks, troughs, old values, and the newest value without
        replacing the x-axis with sample numbers.
        """
        count = min(len(raw_times), len(frame_numbers), len(adc_codes))
        if count <= 0:
            return [], [], []

        raw_times = raw_times[:count]
        frame_numbers = frame_numbers[:count]
        adc_codes = adc_codes[:count]

        if count <= point_limit or point_limit < 6:
            return raw_times, frame_numbers, adc_codes

        # Reserve the first and last sample, then use two real samples
        # (minimum and maximum) from each chronological bucket.
        bucket_count = max(1, (point_limit - 2) // 2)
        interior_count = max(count - 2, 1)
        selected_indices = [0]

        for bucket in range(bucket_count):
            bucket_start = 1 + (bucket * interior_count) // bucket_count
            bucket_end = 1 + ((bucket + 1) * interior_count) // bucket_count
            bucket_end = min(bucket_end, count - 1)
            if bucket_end <= bucket_start:
                continue

            local_indices = range(bucket_start, bucket_end)
            min_index = min(local_indices, key=lambda index: adc_codes[index])
            max_index = max(range(bucket_start, bucket_end), key=lambda index: adc_codes[index])
            if min_index <= max_index:
                selected_indices.extend((min_index, max_index))
            else:
                selected_indices.extend((max_index, min_index))

        selected_indices.append(count - 1)

        # Remove duplicate indices while preserving chronological order.
        ordered_indices = []
        previous = -1
        for index in sorted(set(selected_indices)):
            if index > previous:
                ordered_indices.append(index)
                previous = index

        return (
            [raw_times[index] for index in ordered_indices],
            [frame_numbers[index] for index in ordered_indices],
            [adc_codes[index] for index in ordered_indices],
        )

    def draw_channel_on_axis(self, ax, ch: int, compact: bool = False):
        # Use the complete retained channel history.  As elapsed time grows,
        # the x-axis expands from the oldest retained frame to the newest one,
        # so past values remain visible and the trace becomes horizontally compact.
        all_raw_times = list(self.series[ch]["x"])
        all_frame_numbers = list(self.series[ch]["frame"])
        all_adc_codes = list(self.series[ch]["y"])

        render_limit = ADC_GRID_MAX_RENDER_POINTS if compact else ADC_SINGLE_MAX_RENDER_POINTS
        raw_frame_times, frame_numbers, adc_codes = self.compact_history_for_plot(
            all_raw_times,
            all_frame_numbers,
            all_adc_codes,
            render_limit,
        )
        frame_times_seconds = self.interpolate_frame_time_axis(raw_frame_times, frame_numbers)
        ys = [self.app.adc_code_to_voltage(code) for code in adc_codes]

        if frame_times_seconds:
            marker_size = 2.0 if compact else 2.8
            line_width = 0.8 if compact else 1.0
            ax.plot(
                frame_times_seconds,
                ys,
                linewidth=line_width,
                marker="o",
                markersize=marker_size,
                markevery=1,
            )
            ax.plot(frame_times_seconds[-1], ys[-1], marker="o", markersize=6)

            first_time = frame_times_seconds[0]
            last_time = frame_times_seconds[-1]
            tick_seconds = max(self.app.get_fpga_timestamp_tick_seconds(), 1e-9)
            if last_time > first_time:
                padding = max((last_time - first_time) * 0.01, tick_seconds)
                ax.set_xlim(first_time - padding, last_time + padding)
            else:
                ax.set_xlim(first_time - tick_seconds, last_time + tick_seconds)

            retained_count = len(all_adc_codes)
            rendered_count = len(adc_codes)
            history_span = max(last_time - first_time, 0.0)
            latest_text = (
                f"time={last_time:.6f} s | latest={ys[-1]:.6f} V | "
                f"history={history_span:.3f} s | stored={retained_count} | shown={rendered_count}"
            )
        else:
            ax.text(
                0.5,
                0.5,
                f"{adc_channel_name(ch)}: no data",
                ha="center",
                va="center",
                transform=ax.transAxes,
            )
            latest_text = "no data"

        ax.set_title(
            f"{adc_channel_name(ch)} LIVE - {latest_text}",
            fontsize=9 if compact else 11,
            loc="left",
        )
        ax.set_xlabel("FPGA telemetry time (s, cumulative history)")
        ax.set_ylabel("ADC input voltage (V)")
        ax.set_ylim(0.0, self.app.get_adc_full_scale_voltage())
        ax.ticklabel_format(axis="x", style="plain", useOffset=False)
        ax.grid(True)

    def adc3_active_pair_count(self) -> int:
        """Return the number of address pairs currently enabled in the ADC command."""
        return max(1, sum(1 for var in self.channel_vars if var.get()))

    def adc3_reference_for_codes(self, ch: int, adc_codes: list[int]) -> tuple[list[int], dict]:
        """Fit the exact 64-entry ADC3 model to the displayed received samples.

        The model phase at the beginning of a GUI capture is not known, so all
        64 possible starting phases are tested and the minimum-square-error
        phase is selected. The per-channel phase advance accounts for the number
        of enabled channel pairs because the HDL model advances once per ADC
        conversion, not once per sample of a specific channel.
        """
        if self.adc_name != "ADC3" or not adc_codes:
            return [], {}

        active_pairs = self.adc3_active_pair_count()
        phase_step = (ADC3_MODEL_PHASE_STEP * active_pairs) % len(ADC3_MODEL_LUT)
        if phase_step == 0:
            phase_step = len(ADC3_MODEL_LUT)

        if 1 <= ch <= 6:
            pair_index = ch - 1
            output_offset = 0
        elif 7 <= ch <= 12:
            pair_index = ch - 7
            output_offset = ADC3_MODEL_DOUTB_PHASE_OFFSET
        else:
            return [], {}

        fixed_offset = (
            pair_index * ADC3_MODEL_PAIR_PHASE_OFFSET + output_offset
        ) % len(ADC3_MODEL_LUT)

        best_phase = 0
        best_error = None
        for candidate_phase in range(len(ADC3_MODEL_LUT)):
            error = 0
            for index, code in enumerate(adc_codes):
                lut_index = (
                    candidate_phase + fixed_offset + index * phase_step
                ) % len(ADC3_MODEL_LUT)
                delta = int(code) - ADC3_MODEL_LUT[lut_index]
                error += delta * delta
            if best_error is None or error < best_error:
                best_error = error
                best_phase = candidate_phase

        reference = [
            ADC3_MODEL_LUT[
                (best_phase + fixed_offset + index * phase_step)
                % len(ADC3_MODEL_LUT)
            ]
            for index in range(len(adc_codes))
        ]
        cycle_samples = len(ADC3_MODEL_LUT) // math.gcd(
            len(ADC3_MODEL_LUT), phase_step
        )
        rms_error = math.sqrt((best_error or 0) / max(len(adc_codes), 1))
        return reference, {
            "active_pairs": active_pairs,
            "phase_step": phase_step,
            "cycle_samples": cycle_samples,
            "best_phase": best_phase,
            "rms_error_counts": rms_error,
            "fixed_offset": fixed_offset,
        }

    @staticmethod
    def median_positive_delta(values: list[float]) -> float | None:
        deltas = [
            values[index] - values[index - 1]
            for index in range(1, len(values))
            if values[index] > values[index - 1]
        ]
        if not deltas:
            return None
        deltas.sort()
        middle = len(deltas) // 2
        if len(deltas) % 2:
            return deltas[middle]
        return 0.5 * (deltas[middle - 1] + deltas[middle])

    def capture_slice_for_single_plot(self, ch: int, item: dict) -> tuple[list[float], list[int], list[int]]:
        all_raw_times = list(self.series[ch]["x"])
        all_frame_numbers = list(self.series[ch]["frame"])
        all_adc_codes = list(self.series[ch]["y"])
        count = min(len(all_raw_times), len(all_frame_numbers), len(all_adc_codes))
        if count <= 0:
            return [], [], []

        total_received = self.channel_sample_counts[ch]
        first_retained_global = total_received - count
        capture_start_global = int(item.get("capture_start_global", first_retained_global))
        start_offset = max(0, capture_start_global - first_retained_global)
        start_offset = min(start_offset, count)
        return (
            all_raw_times[start_offset:count],
            all_frame_numbers[start_offset:count],
            all_adc_codes[start_offset:count],
        )

    def draw_recent_live_channel_on_axis(self, ax, ch: int, item: dict):
        raw_times, frame_numbers, adc_codes = self.capture_slice_for_single_plot(ch, item)

        model_meta = {}
        if self.adc_name == "ADC3":
            # Determine the exact number of samples in four cycles for the
            # currently enabled pair count. No min/max compaction is used in
            # this recent window, so the received waveform remains clean.
            _, provisional_meta = self.adc3_reference_for_codes(ch, adc_codes[-64:] if adc_codes else [])
            cycle_samples = int(provisional_meta.get("cycle_samples", 64))
            recent_limit = max(cycle_samples * ADC3_MODEL_RECENT_CYCLES, cycle_samples)
        else:
            recent_limit = 256

        raw_times = raw_times[-recent_limit:]
        frame_numbers = frame_numbers[-recent_limit:]
        adc_codes = adc_codes[-recent_limit:]
        frame_times_seconds = self.interpolate_frame_time_axis(raw_times, frame_numbers)
        voltages = [self.app.adc_code_to_voltage(code) for code in adc_codes]

        if not adc_codes:
            ax.text(
                0.5,
                0.5,
                "Live capture started. Waiting for the first telemetry sample...",
                ha="center",
                va="center",
                transform=ax.transAxes,
            )
            ax.set_title(f"{adc_channel_name(ch)} live capture", loc="left")
        else:
            ax.plot(
                frame_times_seconds,
                voltages,
                linewidth=0.9,
                marker="o",
                markersize=3.0,
                markevery=1,
                label="Received values",
            )
            ax.plot(
                frame_times_seconds[-1],
                voltages[-1],
                marker="o",
                markersize=6,
            )

            reference_codes, model_meta = self.adc3_reference_for_codes(ch, adc_codes)
            if reference_codes:
                reference_voltages = [
                    self.app.adc_code_to_voltage(code) for code in reference_codes
                ]
                ax.plot(
                    frame_times_seconds,
                    reference_voltages,
                    linestyle="--",
                    linewidth=1.1,
                    label="Exact ADC3 HDL model",
                )
                ax.legend(loc="upper right")

            first_time = frame_times_seconds[0]
            last_time = frame_times_seconds[-1]
            tick_seconds = max(self.app.get_fpga_timestamp_tick_seconds(), 1e-9)
            if last_time > first_time:
                padding = max((last_time - first_time) * 0.02, tick_seconds)
                ax.set_xlim(first_time - padding, last_time + padding)
            else:
                ax.set_xlim(first_time - tick_seconds, last_time + tick_seconds)

            sample_period = self.median_positive_delta(frame_times_seconds)
            timing_text = ""
            if sample_period is not None and sample_period > 0:
                sample_rate = 1.0 / sample_period
                timing_text = f" | sample rate~{sample_rate:.2f} Sa/s"
                if model_meta:
                    model_period = sample_period * model_meta["cycle_samples"]
                    if model_period > 0:
                        timing_text += f" | model sine~{1.0 / model_period:.2f} Hz"

            if model_meta:
                model_text = (
                    f"LUT=64, conversion step=1, active pairs={model_meta['active_pairs']}, "
                    f"channel step={model_meta['phase_step']}, cycle={model_meta['cycle_samples']} samples, "
                    f"fit RMS={model_meta['rms_error_counts']:.1f} counts"
                )
            else:
                model_text = "recent uncompressed live samples"

            ax.set_title(
                f"{adc_channel_name(ch)} LIVE | {model_text}{timing_text}",
                fontsize=10,
                loc="left",
            )

        ax.set_xlabel("FPGA telemetry time (s, uniformly reconstructed from frame timestamps)")
        ax.set_ylabel("ADC input voltage (V)")
        ax.set_ylim(0.0, self.app.get_adc_full_scale_voltage())
        ax.ticklabel_format(axis="x", style="plain", useOffset=False)
        ax.grid(True)

        status_var = item.get("status_var")
        if status_var is not None:
            captured = len(self.capture_slice_for_single_plot(ch, item)[2])
            if model_meta:
                status_var.set(
                    f"Live samples since Open selected: {captured} | "
                    f"ADC3 model: 64-point LUT, DOUTB +16 samples (90 degrees), "
                    f"pair offset +3 samples."
                )
            else:
                status_var.set(f"Live samples since Open selected: {captured}")

    def set_single_view_mode(self, ch: int):
        item = self.single_plot_windows.get(ch)
        if not item:
            return
        item["view_locked"] = False
        item["view_limits"] = None
        self.redraw_one_single_plot(ch)

    def restart_single_live_capture(self, ch: int, auto_send: bool = True):
        item = self.single_plot_windows.get(ch)
        if not item:
            return
        # Include the latest already-received value so the graph is not blank at
        # the instant Open selected is pressed, then append new values live.
        item["capture_start_global"] = max(0, self.channel_sample_counts[ch] - 1)
        item["view_locked"] = False
        item["view_limits"] = None
        view_mode_var = item.get("view_mode_var")
        if view_mode_var is not None:
            view_mode_var.set(ADC_SINGLE_VIEW_RECENT)

        status_var = item.get("status_var")
        if auto_send and self.app.sock is not None and self.app.active_mode is not None:
            try:
                packet = self.build_packet()
                self.app.set_adc_active_channels(
                    self.source_id, self.selected_channel_numbers()
                )
                self.app.queue_packet_for_send(packet, f"ADC/{self.adc_name}")
                self.preview_var.set(f"Sent/queued: {bytes_to_hex(packet)}")
                if status_var is not None:
                    status_var.set(
                        "Open selected started a new live capture and sent the current ADC enable command."
                    )
            except Exception as exc:
                if status_var is not None:
                    status_var.set(f"Live capture opened, but command send failed: {exc}")
        elif status_var is not None:
            status_var.set(
                "Live capture opened. Connect first or send the ADC command to receive new values."
            )
        self.plot_dirty = True
        self.redraw_one_single_plot(ch)

    def channel_from_combo_text(self, text: str) -> int | None:
        text = text.strip().upper()
        if not text.startswith("CH"):
            return None
        try:
            ch = int(text[2:], 10)
        except ValueError:
            return None
        return ch if ch in self.series else None

    def open_selected_single_plot(self):
        ch = self.channel_from_combo_text(self.single_channel_var.get())
        if ch is None:
            messagebox.showinfo("No channel selected", "Enable a channel pair first, then select CHx.")
            return
        self.open_single_channel_window(ch, start_live_capture=True)

    def on_grid_plot_click(self, event):
        if event.dblclick and event.inaxes in self.plot_axes_channel_map:
            self.open_single_channel_window(
                self.plot_axes_channel_map[event.inaxes],
                start_live_capture=False,
            )

    def open_single_channel_window(self, ch: int, start_live_capture: bool = False):
        if not HAS_MATPLOTLIB:
            messagebox.showerror("matplotlib missing", "Install matplotlib first: python -m pip install matplotlib")
            return
        existing = self.single_plot_windows.get(ch)
        if existing is not None:
            win = existing.get("window")
            if win is not None and win.winfo_exists():
                win.lift()
                win.focus_force()
                if start_live_capture:
                    self.restart_single_live_capture(ch, auto_send=True)
                else:
                    self.redraw_one_single_plot(ch)
                return

        win = tk.Toplevel(self.frame)
        win.title(f"{self.adc_name} {adc_channel_name(ch)}")
        win.geometry("1040x700")
        win.columnconfigure(0, weight=1)
        win.rowconfigure(2, weight=1)

        controls = ttk.Frame(win, padding=(8, 8, 8, 0))
        controls.grid(row=0, column=0, sticky="ew")
        controls.columnconfigure(0, weight=1)
        ttk.Label(
            controls,
            text="Open selected starts live capture. Box zoom remains fixed during live updates.",
        ).grid(row=0, column=0, sticky="w")

        view_mode_var = tk.StringVar(
            value=ADC_SINGLE_VIEW_RECENT if start_live_capture else ADC_SINGLE_VIEW_FULL
        )
        ttk.Label(controls, text="View:").grid(row=0, column=1, padx=(8, 4))
        view_combo = ttk.Combobox(
            controls,
            textvariable=view_mode_var,
            values=(ADC_SINGLE_VIEW_RECENT, ADC_SINGLE_VIEW_FULL),
            state="readonly",
            width=28,
        )
        view_combo.grid(row=0, column=2, padx=(0, 8))

        status_var = tk.StringVar(value="Preparing plot...")
        ttk.Label(win, textvariable=status_var, padding=(8, 4, 8, 0)).grid(
            row=1, column=0, sticky="ew"
        )

        fig = Figure(figsize=(9.6, 5.6), dpi=100)
        canvas = FigureCanvasTkAgg(fig, master=win)
        canvas.get_tk_widget().grid(row=2, column=0, sticky="nsew", padx=8, pady=(6, 0))
        toolbar = NavigationToolbar2Tk(canvas, win, pack_toolbar=False)
        toolbar.update()
        toolbar.grid(row=3, column=0, sticky="ew", padx=8)

        self.single_plot_windows[ch] = {
            "window": win,
            "figure": fig,
            "canvas": canvas,
            "toolbar": toolbar,
            "view_locked": False,
            "view_limits": None,
            "view_mode_var": view_mode_var,
            "status_var": status_var,
            "capture_start_global": max(0, self.channel_sample_counts[ch] - 1),
        }

        ttk.Button(
            controls,
            text="Restart live capture",
            command=lambda channel=ch: self.restart_single_live_capture(channel, auto_send=True),
        ).grid(row=0, column=3, padx=(0, 8))
        ttk.Button(
            controls,
            text="Box zoom",
            command=lambda channel=ch: self.activate_single_box_zoom(channel),
        ).grid(row=0, column=4, padx=(0, 8))
        ttk.Button(
            controls,
            text="Fit all / Live",
            command=lambda channel=ch: self.reset_single_view(channel),
        ).grid(row=0, column=5)

        view_combo.bind(
            "<<ComboboxSelected>>",
            lambda _event, channel=ch: self.set_single_view_mode(channel),
        )
        canvas.mpl_connect(
            "button_release_event",
            lambda event, channel=ch: self.on_single_zoom_release(channel, event),
        )
        canvas.mpl_connect("scroll_event", self.on_scroll_zoom)
        win.protocol("WM_DELETE_WINDOW", lambda channel=ch: self.close_single_channel_window(channel))

        if start_live_capture:
            self.restart_single_live_capture(ch, auto_send=True)
        else:
            status_var.set("Full retained history view opened from the existing samples.")
            self.redraw_one_single_plot(ch)

    def activate_single_box_zoom(self, ch: int):
        item = self.single_plot_windows.get(ch)
        if not item:
            return
        toolbar = item.get("toolbar")
        if toolbar is not None:
            toolbar.zoom()

    def on_single_zoom_release(self, ch: int, event):
        item = self.single_plot_windows.get(ch)
        if not item or event.inaxes is None:
            return
        toolbar = item.get("toolbar")
        mode_text = str(getattr(toolbar, "mode", "")).lower() if toolbar is not None else ""
        if "zoom" not in mode_text:
            return
        item["view_locked"] = True
        item["view_limits"] = (event.inaxes.get_xlim(), event.inaxes.get_ylim())

    def reset_single_view(self, ch: int):
        item = self.single_plot_windows.get(ch)
        if not item:
            return
        item["view_locked"] = False
        item["view_limits"] = None
        toolbar = item.get("toolbar")
        if toolbar is not None:
            mode_text = str(getattr(toolbar, "mode", "")).lower()
            if "zoom" in mode_text:
                toolbar.zoom()
        self.redraw_one_single_plot(ch)

    def close_single_channel_window(self, ch: int):
        item = self.single_plot_windows.pop(ch, None)
        if item is not None:
            win = item.get("window")
            if win is not None and win.winfo_exists():
                win.destroy()

    def redraw_single_plot_windows(self):
        for ch in list(self.single_plot_windows.keys()):
            self.redraw_one_single_plot(ch)

    def redraw_one_single_plot(self, ch: int):
        item = self.single_plot_windows.get(ch)
        if not item:
            return
        win = item.get("window")
        fig = item.get("figure")
        canvas = item.get("canvas")
        if win is None or not win.winfo_exists() or fig is None or canvas is None:
            self.single_plot_windows.pop(ch, None)
            return

        if item.get("view_locked") and fig.axes:
            try:
                old_axis = fig.axes[0]
                item["view_limits"] = (old_axis.get_xlim(), old_axis.get_ylim())
            except Exception:
                pass

        fig.clear()
        ax = fig.add_subplot(111)
        view_mode_var = item.get("view_mode_var")
        view_mode = view_mode_var.get() if view_mode_var is not None else ADC_SINGLE_VIEW_FULL
        if view_mode == ADC_SINGLE_VIEW_RECENT:
            self.draw_recent_live_channel_on_axis(ax, ch, item)
        else:
            self.draw_channel_on_axis(ax, ch, compact=False)
            status_var = item.get("status_var")
            if status_var is not None:
                status_var.set(
                    f"Full retained history: {len(self.series[ch]['y'])} stored values. "
                    "Choose Recent live / AD7266 model for a clean four-cycle view."
                )

        if item.get("view_locked") and item.get("view_limits") is not None:
            x_limits, y_limits = item["view_limits"]
            ax.set_xlim(*x_limits)
            ax.set_ylim(*y_limits)
        fig.tight_layout()
        canvas.draw()

    def on_scroll_zoom(self, event):
        ax = event.inaxes
        if ax is None:
            return
        base_scale = 1.2
        scale_factor = 1 / base_scale if event.button == "up" else base_scale
        x_left, x_right = ax.get_xlim()
        y_bottom, y_top = ax.get_ylim()
        x_center = event.xdata if event.xdata is not None else (x_left + x_right) / 2
        y_center = event.ydata if event.ydata is not None else (y_bottom + y_top) / 2
        new_width = (x_right - x_left) * scale_factor
        new_height = (y_top - y_bottom) * scale_factor
        ax.set_xlim(x_center - new_width / 2, x_center + new_width / 2)
        ax.set_ylim(y_center - new_height / 2, y_center + new_height / 2)

        if ax in self.plot_axes_channel_map:
            self.grid_view_locked = True
            self.capture_grid_view_limits()
        else:
            for item in self.single_plot_windows.values():
                figure = item.get("figure")
                if figure is ax.figure:
                    item["view_locked"] = True
                    item["view_limits"] = (ax.get_xlim(), ax.get_ylim())
                    break

        ax.figure.canvas.draw_idle()


class AdcMainTab:
    def __init__(self, app, notebook: ttk.Notebook):
        self.app = app
        self.frame = ttk.Frame(notebook, padding=6)
        notebook.add(self.frame, text="ADC")
        self.frame.columnconfigure(0, weight=1)
        self.frame.rowconfigure(0, weight=1)
        self.notebook = ttk.Notebook(self.frame)
        self.notebook.grid(row=0, column=0, sticky="nsew")
        self.subtabs_by_source = {}
        for name, source_id in ADC_SOURCES.items():
            tab = AdcChannelSubTab(app, self.notebook, name, source_id)
            self.subtabs_by_source[source_id] = tab

    def get_tab_for_source(self, source: int):
        return self.subtabs_by_source.get(source)

    def flush_pending_logs(self):
        for tab in self.subtabs_by_source.values():
            tab.flush_pending_logs()

    def redraw_dirty_plots(self):
        for tab in self.subtabs_by_source.values():
            tab.redraw_plot(force=False)


class HpuCoreTab:
    """HPU register control, event monitor, plots, and data export."""

    def __init__(self, app, notebook: ttk.Notebook):
        self.app = app
        self.pending_log: list[str] = []
        self.register_values: dict[int, int] = {}
        self.register_axi_response: dict[int, int] = {}
        self.register_items: dict[int, str] = {}
        self.event_records = deque(maxlen=HPU_EVENT_HISTORY_LIMIT)
        self.event_times = deque()
        self.address_histogram = [0] * (HPU_EVENT_ADDRESS_MASK + 1)
        self.total_events = 0
        self.dropped_history_events = 0
        self.plot_dirty = True
        self.auto_poll_index = 0
        self._auto_after_id = None

        self.frame = ttk.Frame(notebook, padding=6)
        notebook.add(self.frame, text="HPU Core")
        self.frame.columnconfigure(0, weight=1)
        self.frame.rowconfigure(1, weight=1)

        header = ttk.Frame(self.frame, padding=(4, 2, 4, 4))
        header.grid(row=0, column=0, sticky="ew")
        header.columnconfigure(6, weight=1)
        ttk.Label(header, text="HPU Core source ID: 0x09 | command/control transport: UDP only").grid(
            row=0, column=0, columnspan=3, sticky="w"
        )
        self.summary_var = tk.StringVar(value="Events=0 | current rate=0.0 events/s | no HPU response yet")
        ttk.Label(header, textvariable=self.summary_var).grid(row=0, column=6, sticky="e")

        self.notebook = ttk.Notebook(self.frame)
        self.notebook.grid(row=1, column=0, sticky="nsew")
        self._build_control_page()
        self._build_events_page()
        self._build_log_page()
        self._schedule_auto_poll()

    def _build_control_page(self):
        page = ttk.Frame(self.notebook, padding=8)
        self.notebook.add(page, text="Registers and configuration")
        page.columnconfigure(0, weight=1)
        page.rowconfigure(3, weight=1)

        project_box = ttk.LabelFrame(page, text="Locked project configuration")
        project_box.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        project_box.columnconfigure(6, weight=1)
        ttk.Button(
            project_box,
            text="Apply AUX PAER + OnlyEventsRx",
            command=self.apply_project_configuration,
        ).grid(row=0, column=0, padx=8, pady=8)
        ttk.Button(
            project_box,
            text="Read project registers",
            command=self.read_project_registers,
        ).grid(row=0, column=1, padx=(0, 8), pady=8)
        self.auto_status_var = tk.BooleanVar(value=True)
        ttk.Checkbutton(
            project_box,
            text="Auto status",
            variable=self.auto_status_var,
        ).grid(row=0, column=2, padx=(4, 4), pady=8)
        ttk.Label(project_box, text="Interval (ms)").grid(row=0, column=3, padx=(8, 4), pady=8)
        self.auto_interval_var = tk.StringVar(value=str(HPU_DEFAULT_AUTO_STATUS_MS))
        ttk.Entry(project_box, textvariable=self.auto_interval_var, width=8).grid(
            row=0, column=4, padx=(0, 8), pady=8
        )
        ttk.Label(
            project_box,
            text="Writes RX_CNFG=0x02000100, AUX_CTRL=0x00000002, CTRL=0x00002002.",
        ).grid(row=0, column=6, sticky="w", padx=8, pady=8)

        raw_box = ttk.LabelFrame(page, text="Raw AXI-Lite register browser")
        raw_box.grid(row=1, column=0, sticky="ew", pady=(0, 8))
        raw_box.columnconfigure(10, weight=1)
        ttk.Label(raw_box, text="Address").grid(row=0, column=0, padx=(8, 4), pady=8)
        self.address_var = tk.StringVar(value="0x00")
        ttk.Entry(raw_box, textvariable=self.address_var, width=9).grid(row=0, column=1, padx=(0, 8), pady=8)
        ttk.Label(raw_box, text="Write data").grid(row=0, column=2, padx=(0, 4), pady=8)
        self.write_data_var = tk.StringVar(value="0x00000000")
        ttk.Entry(raw_box, textvariable=self.write_data_var, width=14).grid(row=0, column=3, padx=(0, 8), pady=8)
        ttk.Label(raw_box, text="WSTRB").grid(row=0, column=4, padx=(0, 4), pady=8)
        self.write_strobe_var = tk.StringVar(value="0x0F")
        ttk.Entry(raw_box, textvariable=self.write_strobe_var, width=7).grid(row=0, column=5, padx=(0, 8), pady=8)
        ttk.Button(raw_box, text="Read", command=self.send_raw_read).grid(row=0, column=6, padx=(0, 6), pady=8)
        ttk.Button(raw_box, text="Write", command=self.send_raw_write).grid(row=0, column=7, padx=(0, 6), pady=8)
        ttk.Button(raw_box, text="Read all", command=self.read_all_registers).grid(row=0, column=8, padx=(0, 6), pady=8)
        self.command_preview_var = tk.StringVar(value="TX preview: -")
        ttk.Label(raw_box, textvariable=self.command_preview_var, wraplength=500).grid(
            row=0, column=10, sticky="w", padx=8, pady=8
        )

        table_box = ttk.LabelFrame(page, text="HPU register table")
        table_box.grid(row=3, column=0, sticky="nsew")
        table_box.columnconfigure(0, weight=1)
        table_box.rowconfigure(0, weight=1)
        columns = ("address", "name", "access", "value", "axi", "decoded", "description")
        self.register_tree = ttk.Treeview(table_box, columns=columns, show="headings", height=18)
        headings = {
            "address": "Address",
            "name": "Register",
            "access": "Access",
            "value": "Last value",
            "axi": "AXI",
            "decoded": "Decoded",
            "description": "Description",
        }
        widths = {"address": 70, "name": 190, "access": 60, "value": 105, "axi": 55, "decoded": 290, "description": 390}
        for column in columns:
            self.register_tree.heading(column, text=headings[column])
            self.register_tree.column(column, width=widths[column], anchor="w", stretch=column in ("decoded", "description"))
        self.register_tree.grid(row=0, column=0, sticky="nsew")
        table_scroll = ttk.Scrollbar(table_box, orient="vertical", command=self.register_tree.yview)
        table_scroll.grid(row=0, column=1, sticky="ns")
        self.register_tree.configure(yscrollcommand=table_scroll.set)
        self.register_tree.bind("<<TreeviewSelect>>", self.on_register_selected)
        for address, name, access, description in HPU_REGISTER_MAP:
            item = self.register_tree.insert(
                "", "end", values=(f"0x{address:02X}", name, access, "-", "-", "-", description)
            )
            self.register_items[address] = item

    def _build_events_page(self):
        page = ttk.Frame(self.notebook, padding=8)
        self.notebook.add(page, text="Events and plots")
        page.columnconfigure(0, weight=1)
        page.rowconfigure(2, weight=1)
        page.rowconfigure(3, weight=2)

        actions = ttk.Frame(page)
        actions.grid(row=0, column=0, sticky="ew", pady=(0, 8))
        actions.columnconfigure(8, weight=1)
        ttk.Button(actions, text="Clear events", command=self.clear_events).grid(row=0, column=0, padx=(0, 6))
        ttk.Button(actions, text="Save CSV", command=self.save_events_csv).grid(row=0, column=1, padx=(0, 6))
        ttk.Button(actions, text="Save binary raw32", command=self.save_events_binary).grid(row=0, column=2, padx=(0, 6))
        self.event_status_var = tk.StringVar(value="No HPU events received.")
        ttk.Label(actions, textvariable=self.event_status_var).grid(row=0, column=8, sticky="e")

        recent_box = ttk.LabelFrame(page, text="Most recent decoded HPU events")
        recent_box.grid(row=2, column=0, sticky="nsew", pady=(0, 8))
        recent_box.columnconfigure(0, weight=1)
        recent_box.rowconfigure(0, weight=1)
        columns = ("number", "host_time", "tel_seq", "fpga_time", "raw", "address")
        self.event_tree = ttk.Treeview(recent_box, columns=columns, show="headings", height=8)
        for column, heading, width in (
            ("number", "#", 70),
            ("host_time", "Host time", 110),
            ("tel_seq", "TEL_SEQ", 75),
            ("fpga_time", "FPGA TIME", 90),
            ("raw", "Raw event", 120),
            ("address", "Decoded 9-bit address", 160),
        ):
            self.event_tree.heading(column, text=heading)
            self.event_tree.column(column, width=width, anchor="w")
        self.event_tree.grid(row=0, column=0, sticky="nsew")
        event_scroll = ttk.Scrollbar(recent_box, orient="vertical", command=self.event_tree.yview)
        event_scroll.grid(row=0, column=1, sticky="ns")
        self.event_tree.configure(yscrollcommand=event_scroll.set)

        plot_box = ttk.LabelFrame(page, text="Address histogram and host-side event rate")
        plot_box.grid(row=3, column=0, sticky="nsew")
        plot_box.columnconfigure(0, weight=1)
        plot_box.rowconfigure(0, weight=1)
        self.plot_figure = None
        self.plot_canvas = None
        if HAS_MATPLOTLIB:
            self.plot_figure = Figure(figsize=(10.8, 4.2), dpi=100)
            self.plot_canvas = FigureCanvasTkAgg(self.plot_figure, master=plot_box)
            self.plot_canvas.get_tk_widget().grid(row=0, column=0, sticky="nsew", padx=6, pady=6)
        else:
            ttk.Label(plot_box, text="Install matplotlib to display HPU histogram and event-rate charts.").grid(
                row=0, column=0, sticky="nsew", padx=8, pady=8
            )

    def _build_log_page(self):
        page = ttk.Frame(self.notebook, padding=8)
        self.notebook.add(page, text="Raw log")
        page.columnconfigure(0, weight=1)
        page.rowconfigure(0, weight=1)
        self.log_text = tk.Text(page, wrap="word", state="disabled")
        self.log_text.grid(row=0, column=0, sticky="nsew")
        scroll = ttk.Scrollbar(page, orient="vertical", command=self.log_text.yview)
        scroll.grid(row=0, column=1, sticky="ns")
        self.log_text.configure(yscrollcommand=scroll.set)
        buttons = ttk.Frame(page)
        buttons.grid(row=1, column=0, columnspan=2, sticky="e", pady=(8, 0))
        ttk.Button(buttons, text="Clear log", command=self.clear_log).grid(row=0, column=0, padx=(0, 6))
        ttk.Button(buttons, text="Save log", command=self.save_log).grid(row=0, column=1)

    @staticmethod
    def parse_hex_value(text: str, maximum: int, field_name: str) -> int:
        value_text = text.strip()
        if not value_text:
            raise ValueError(f"{field_name} is empty.")
        try:
            value = int(value_text, 0)
        except ValueError:
            try:
                value = int(value_text, 16)
            except ValueError as exc:
                raise ValueError(f"{field_name} is not a valid hexadecimal value.") from exc
        if not 0 <= value <= maximum:
            raise ValueError(f"{field_name} must be 0x0..0x{maximum:X}.")
        return value

    def ensure_udp_ready(self):
        if self.app.sock is None or self.app.active_mode is None:
            raise RuntimeError("Open the Ethernet connection first.")
        if self.app.active_mode != "UDP":
            raise RuntimeError("HPU control is enabled only in UDP mode.")

    def build_read_packet(self, address: int) -> bytes:
        payload = bytes((HPU_CMD_READ, address & 0xFF))
        return bytes((VERSION, self.app.pack_seq & 0xFF, SOURCE_HPU, tc_length_from_payload_size(len(payload)))) + payload

    def build_write_packet(self, address: int, data: int, strobe: int) -> bytes:
        payload = bytes((HPU_CMD_WRITE, address & 0xFF, strobe & 0x0F, 0x00)) + data.to_bytes(4, "big")
        return bytes((VERSION, self.app.pack_seq & 0xFF, SOURCE_HPU, tc_length_from_payload_size(len(payload)))) + payload

    def queue_read(self, address: int, label: str = "raw-read"):
        self.ensure_udp_ready()
        packet = self.build_read_packet(address)
        self.app.queue_packet_for_send(packet, f"HPU/{label}/0x{address:02X}")
        self.command_preview_var.set(f"Read queued: {bytes_to_hex(packet)}")

    def queue_write(self, address: int, data: int, strobe: int = 0x0F, label: str = "raw-write"):
        self.ensure_udp_ready()
        packet = self.build_write_packet(address, data, strobe)
        self.app.queue_packet_for_send(packet, f"HPU/{label}/0x{address:02X}")
        self.command_preview_var.set(f"Write queued: {bytes_to_hex(packet)}")

    def send_raw_read(self):
        try:
            address = self.parse_hex_value(self.address_var.get(), 0xFF, "Address")
            self.queue_read(address)
        except Exception as exc:
            messagebox.showerror("HPU read error", str(exc))

    def send_raw_write(self):
        try:
            address = self.parse_hex_value(self.address_var.get(), 0xFF, "Address")
            data = self.parse_hex_value(self.write_data_var.get(), 0xFFFFFFFF, "Write data")
            strobe = self.parse_hex_value(self.write_strobe_var.get(), 0x0F, "WSTRB")
            self.queue_write(address, data, strobe)
        except Exception as exc:
            messagebox.showerror("HPU write error", str(exc))

    def apply_project_configuration(self):
        try:
            self.ensure_udp_ready()
            for address, data, strobe, description in HPU_PROJECT_CONFIGURATION:
                self.queue_write(address, data, strobe, label="project-config")
                self.append_rx(f"[{now_stamp()}] Project configuration queued | {description}")
        except Exception as exc:
            messagebox.showerror("HPU project configuration error", str(exc))

    def read_project_registers(self):
        try:
            self.ensure_udp_ready()
            for address in HPU_STATUS_POLL_ADDRESSES:
                self.queue_read(address, label="project-status")
        except Exception as exc:
            messagebox.showerror("HPU status read error", str(exc))

    def read_all_registers(self):
        try:
            self.ensure_udp_ready()
            for address, _name, _access, _description in HPU_REGISTER_MAP:
                self.queue_read(address, label="read-all")
        except Exception as exc:
            messagebox.showerror("HPU register read error", str(exc))

    def _schedule_auto_poll(self):
        try:
            interval = int(self.auto_interval_var.get()) if hasattr(self, "auto_interval_var") else HPU_DEFAULT_AUTO_STATUS_MS
        except Exception:
            interval = HPU_DEFAULT_AUTO_STATUS_MS
        interval = max(100, min(60000, interval))
        try:
            self._auto_after_id = self.frame.after(interval, self._auto_poll_tick)
        except tk.TclError:
            self._auto_after_id = None

    def _auto_poll_tick(self):
        self._auto_after_id = None
        try:
            if (
                self.auto_status_var.get()
                and self.app.sock is not None
                and self.app.active_mode == "UDP"
            ):
                address = HPU_STATUS_POLL_ADDRESSES[self.auto_poll_index % len(HPU_STATUS_POLL_ADDRESSES)]
                self.auto_poll_index += 1
                self.queue_read(address, label="auto-status")
        except Exception as exc:
            self.append_rx(f"[{now_stamp()}] Auto-status error: {exc}")
        finally:
            self._schedule_auto_poll()

    def on_register_selected(self, _event=None):
        selection = self.register_tree.selection()
        if not selection:
            return
        values = self.register_tree.item(selection[0], "values")
        if not values:
            return
        self.address_var.set(values[0])
        try:
            address = int(values[0], 16)
            if address in self.register_values:
                self.write_data_var.set(f"0x{self.register_values[address]:08X}")
        except Exception:
            pass

    @staticmethod
    def decode_register_value(address: int, value: int) -> str:
        if address == 0x00:
            return (
                f"OnlyEventsRx={(value >> 13) & 1}, OnlyEventsTx={(value >> 14) & 1}, "
                f"DMAIf={(value >> 1) & 1}, DMA_running={value & 1}"
            )
        if address == 0x18:
            return f"raw_irq=0x{value & 0xFFFF:04X}, global_err=0x{(value >> 16) & 0xF:X}"
        if address == 0x40:
            return f"left_PAER={(value >> 1) & 1}, right_PAER={(value >> 17) & 1}"
        if address == 0x48:
            return (
                f"REQ_active={value & 1}, ACK_active={(value >> 1) & 1}, "
                f"sample={(value >> 8) & 0xFF}, ack_set={(value >> 16) & 0xFF}, "
                f"ack_release={(value >> 24) & 0xFF}"
            )
        if address == 0x50:
            return f"RX capabilities=0x{value & 0xFF:02X}, TX capabilities=0x{(value >> 8) & 0xFF:02X}"
        if address == 0x5C:
            chars = bytes(((value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF))
            name = chars.decode("ascii", errors="replace")
            return f"ID={name}, version={(value >> 4) & 0xF}.{value & 0xF}"
        if address == 0x60:
            return (
                f"AUX_HSSAER={value & 1}, AUX_PAER={(value >> 1) & 1}, "
                f"AUX_GTP={(value >> 2) & 1}, AUX_SpiNN={(value >> 3) & 1}"
            )
        return ""

    def update_register_value(self, address: int, value: int, axi_response: int):
        self.register_values[address] = value
        self.register_axi_response[address] = axi_response
        item = self.register_items.get(address)
        if item is None:
            return
        name, access, description = HPU_REGISTER_BY_ADDRESS[address]
        decoded = self.decode_register_value(address, value) or "-"
        self.register_tree.item(
            item,
            values=(
                f"0x{address:02X}", name, access, f"0x{value:08X}",
                f"0x{axi_response:02X}", decoded, description,
            ),
        )

    def receive_echo(self, line: str):
        self.append_rx(line)

    def receive_telemetry(self, raw: bytes, meta: dict, payload: bytes):
        if not payload:
            self.append_rx(f"[{now_stamp()}] Empty HPU telemetry | RAW={bytes_to_hex(raw)}")
            return
        message_type = payload[0]
        if message_type == HPU_TM_EVENT and len(payload) >= 5:
            raw_event = int.from_bytes(payload[1:5], "big")
            address = raw_event & HPU_EVENT_ADDRESS_MASK
            host_monotonic = time.monotonic()
            record = {
                "index": self.total_events + 1,
                "host_time": time.time(),
                "tel_seq": meta.get("tel_seq", 0),
                "fpga_time": meta.get("time", 0),
                "raw_event": raw_event,
                "address": address,
            }
            if len(self.event_records) == self.event_records.maxlen:
                self.dropped_history_events += 1
            self.event_records.append(record)
            self.event_times.append(host_monotonic)
            self.address_histogram[address] += 1
            self.total_events += 1
            self.plot_dirty = True
            self.event_tree.insert(
                "", "end",
                values=(
                    record["index"],
                    time.strftime("%H:%M:%S", time.localtime(record["host_time"])),
                    f"0x{record['tel_seq']:02X}",
                    f"0x{record['fpga_time']:04X}",
                    f"0x{raw_event:08X}",
                    f"0x{address:03X} ({address})",
                ),
            )
            children = self.event_tree.get_children()
            if len(children) > HPU_RECENT_EVENT_ROWS:
                self.event_tree.delete(*children[: len(children) - HPU_RECENT_EVENT_ROWS])
            if self.app.log_telemetry_var.get() or self.total_events <= 8 or (self.total_events % 64) == 0:
                self.append_rx(
                    f"[{now_stamp()}] HPU event #{self.total_events} | TEL_SEQ=0x{record['tel_seq']:02X}, "
                    f"TIME=0x{record['fpga_time']:04X}, RAW=0x{raw_event:08X}, "
                    f"ADDR9=0x{address:03X} ({address}) | FRAME={bytes_to_hex(raw)}"
                )
            self.update_event_status()
            return

        if message_type == HPU_TM_WRITE_RESPONSE and len(payload) >= 4:
            address = payload[1]
            axi_response = payload[2]
            self.register_axi_response[address] = axi_response
            self.append_rx(
                f"[{now_stamp()}] HPU write response | ADDR=0x{address:02X}, "
                f"AXI_RESP=0x{axi_response:02X}, RAW={bytes_to_hex(raw)}"
            )
            return

        if message_type == HPU_TM_READ_RESPONSE and len(payload) >= 8:
            address = payload[1]
            axi_response = payload[2]
            value = int.from_bytes(payload[4:8], "big")
            self.update_register_value(address, value, axi_response)
            self.append_rx(
                f"[{now_stamp()}] HPU read response | ADDR=0x{address:02X}, "
                f"AXI_RESP=0x{axi_response:02X}, DATA=0x{value:08X}, "
                f"DECODE={self.decode_register_value(address, value) or '-'}, RAW={bytes_to_hex(raw)}"
            )
            return

        if message_type == HPU_TM_ERROR:
            self.append_rx(
                f"[{now_stamp()}] HPU bridge error | PAYLOAD={bytes_to_hex(payload)}, RAW={bytes_to_hex(raw)}"
            )
            return

        self.append_rx(
            f"[{now_stamp()}] Unknown HPU telemetry type 0x{message_type:02X} | "
            f"PAYLOAD={bytes_to_hex(payload)}, RAW={bytes_to_hex(raw)}"
        )

    def current_event_rate(self) -> float:
        now = time.monotonic()
        while self.event_times and self.event_times[0] < now - HPU_RATE_WINDOW_SECONDS:
            self.event_times.popleft()
        one_second_ago = now - 1.0
        count = sum(1 for stamp in self.event_times if stamp >= one_second_ago)
        return float(count)

    def update_event_status(self):
        rate = self.current_event_rate()
        last = self.event_records[-1] if self.event_records else None
        if last:
            self.event_status_var.set(
                f"Events={self.total_events} | rate={rate:.1f} events/s | "
                f"last RAW=0x{last['raw_event']:08X} | ADDR9=0x{last['address']:03X}"
            )
            self.summary_var.set(
                f"Events={self.total_events} | current rate={rate:.1f} events/s | "
                f"history dropped={self.dropped_history_events}"
            )

    def redraw_plot(self, force: bool = False):
        if not force and not self.plot_dirty:
            self.update_event_status()
            return
        self.plot_dirty = False
        self.update_event_status()
        if self.plot_figure is None or self.plot_canvas is None:
            return
        self.plot_figure.clear()
        hist_ax = self.plot_figure.add_subplot(121)
        rate_ax = self.plot_figure.add_subplot(122)

        nonzero = [(address, count) for address, count in enumerate(self.address_histogram) if count]
        if nonzero:
            xs = [item[0] for item in nonzero]
            ys = [item[1] for item in nonzero]
            hist_ax.bar(xs, ys, width=1.0)
        else:
            hist_ax.text(0.5, 0.5, "No HPU events", ha="center", va="center", transform=hist_ax.transAxes)
        hist_ax.set_title("9-bit event-address histogram")
        hist_ax.set_xlabel("Address (0..511)")
        hist_ax.set_ylabel("Count")
        hist_ax.set_xlim(-1, 512)
        hist_ax.grid(True)

        now = time.monotonic()
        while self.event_times and self.event_times[0] < now - HPU_RATE_WINDOW_SECONDS:
            self.event_times.popleft()
        bin_count = int(HPU_RATE_WINDOW_SECONDS / HPU_RATE_BIN_SECONDS)
        bins = [0] * bin_count
        for stamp in self.event_times:
            age = now - stamp
            if 0.0 <= age < HPU_RATE_WINDOW_SECONDS:
                reverse_index = int(age / HPU_RATE_BIN_SECONDS)
                index = bin_count - 1 - reverse_index
                if 0 <= index < bin_count:
                    bins[index] += 1
        xs = [-(HPU_RATE_WINDOW_SECONDS - (index + 1) * HPU_RATE_BIN_SECONDS) for index in range(bin_count)]
        ys = [count / HPU_RATE_BIN_SECONDS for count in bins]
        rate_ax.plot(xs, ys)
        rate_ax.set_title("Host receive event rate")
        rate_ax.set_xlabel("Time relative to now (s)")
        rate_ax.set_ylabel("Events/s")
        rate_ax.grid(True)
        self.plot_figure.tight_layout()
        self.plot_canvas.draw()

    def clear_events(self):
        self.event_records.clear()
        self.event_times.clear()
        self.address_histogram = [0] * (HPU_EVENT_ADDRESS_MASK + 1)
        self.total_events = 0
        self.dropped_history_events = 0
        children = self.event_tree.get_children()
        if children:
            self.event_tree.delete(*children)
        self.event_status_var.set("No HPU events received.")
        self.summary_var.set("Events=0 | current rate=0.0 events/s")
        self.plot_dirty = True
        self.redraw_plot(force=True)

    def save_events_csv(self):
        if not self.event_records:
            messagebox.showinfo("HPU CSV", "No HPU events are available to save.")
            return
        filename = filedialog.asksaveasfilename(
            title="Save HPU events as CSV",
            defaultextension=".csv",
            filetypes=(("CSV files", "*.csv"), ("All files", "*.*")),
        )
        if not filename:
            return
        try:
            with open(filename, "w", newline="", encoding="utf-8") as handle:
                writer = csv.writer(handle)
                writer.writerow(("index", "host_unix_time", "tel_seq", "fpga_timestamp", "raw_event_hex", "raw_event", "address9_hex", "address9"))
                for record in self.event_records:
                    writer.writerow((
                        record["index"], f"{record['host_time']:.9f}", record["tel_seq"], record["fpga_time"],
                        f"0x{record['raw_event']:08X}", record["raw_event"],
                        f"0x{record['address']:03X}", record["address"],
                    ))
            self.append_rx(f"[{now_stamp()}] Saved {len(self.event_records)} HPU events to CSV: {filename}")
        except Exception as exc:
            messagebox.showerror("HPU CSV save error", str(exc))

    def save_events_binary(self):
        if not self.event_records:
            messagebox.showinfo("HPU binary", "No HPU events are available to save.")
            return
        filename = filedialog.asksaveasfilename(
            title="Save HPU raw 32-bit events",
            defaultextension=".bin",
            filetypes=(("Binary files", "*.bin"), ("All files", "*.*")),
        )
        if not filename:
            return
        try:
            with open(filename, "wb") as handle:
                for record in self.event_records:
                    handle.write(record["raw_event"].to_bytes(4, "big"))
            self.append_rx(f"[{now_stamp()}] Saved {len(self.event_records)} raw HPU events to binary: {filename}")
        except Exception as exc:
            messagebox.showerror("HPU binary save error", str(exc))

    def append_rx(self, line: str):
        self.pending_log.append(line)

    def flush_pending_logs(self):
        if not self.pending_log:
            return
        lines = self.pending_log[:MAX_LOG_LINES_PER_FLUSH]
        del self.pending_log[:MAX_LOG_LINES_PER_FLUSH]
        self.log_text.configure(state="normal")
        for line in lines:
            self.log_text.insert("end", line + "\n")
        try:
            line_count = int(self.log_text.index("end-1c").split(".")[0])
            if line_count > MAX_LOG_LINES_PER_BOX:
                delete_to = line_count - MAX_LOG_LINES_PER_BOX + 1
                self.log_text.delete("1.0", f"{delete_to}.0")
        except Exception:
            pass
        self.log_text.see("end")
        self.log_text.configure(state="disabled")

    def clear_log(self):
        self.pending_log.clear()
        self.log_text.configure(state="normal")
        self.log_text.delete("1.0", "end")
        self.log_text.configure(state="disabled")

    def save_log(self):
        filename = filedialog.asksaveasfilename(
            title="Save HPU raw log",
            defaultextension=".txt",
            filetypes=(("Text files", "*.txt"), ("All files", "*.*")),
        )
        if not filename:
            return
        try:
            self.flush_pending_logs()
            content = self.log_text.get("1.0", "end-1c")
            with open(filename, "w", encoding="utf-8") as handle:
                handle.write(content)
        except Exception as exc:
            messagebox.showerror("HPU log save error", str(exc))


class EthernetGuiApp:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.root.title("Mercury XU5 PE1 Ethernet TC/TM GUI - Threaded")
        self.root.geometry("1250x820")
        self.sock = None
        self.active_mode = None
        self.rx_stop = threading.Event()
        self.rx_thread = None
        self.rx_queue = queue.Queue(maxsize=RX_QUEUE_MAX)
        self.tx_queue = queue.Queue(maxsize=TX_QUEUE_MAX)
        self.rx_buffer = bytearray()
        self.pack_seq = 0
        self.dropped_rx_packets = 0
        self.rx_packets = 0
        self.tx_packets = 0
        self.parse_errors = 0
        self.adc_active_channels = {}
        self.tabs = {}
        self.root.protocol("WM_DELETE_WINDOW", self.on_close)
        self.build_ui()
        self.root.after(UI_QUEUE_INTERVAL_MS, self.process_rx_queue)
        self.root.after(LOG_FLUSH_INTERVAL_MS, self.flush_all_logs)
        self.root.after(PLOT_REFRESH_INTERVAL_MS, self.redraw_dirty_plots)
        self.root.after(500, self.update_counters)

    def build_ui(self):
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(2, weight=1)
        top = ttk.Frame(self.root, padding=(10, 8, 10, 4))
        top.grid(row=0, column=0, sticky="ew")
        top.columnconfigure(8, weight=1)
        ttk.Label(top, text="Mode").grid(row=0, column=0, sticky="e", padx=(0, 4))
        self.mode_var = tk.StringVar(value="UDP")
        ttk.Combobox(top, textvariable=self.mode_var, values=SUPPORTED_MODES, state="readonly", width=6).grid(row=0, column=1, sticky="w", padx=(0, 10))
        ttk.Label(top, text="Board IP").grid(row=0, column=2, sticky="e", padx=(0, 4))
        self.ip_var = tk.StringVar(value="192.168.1.50")
        ttk.Entry(top, textvariable=self.ip_var, width=16).grid(row=0, column=3, sticky="w", padx=(0, 10))
        ttk.Label(top, text="Port").grid(row=0, column=4, sticky="e", padx=(0, 4))
        self.port_var = tk.StringVar(value="5001")
        ttk.Entry(top, textvariable=self.port_var, width=7).grid(row=0, column=5, sticky="w", padx=(0, 10))
        ttk.Label(top, text="Local UDP port").grid(row=0, column=6, sticky="e", padx=(0, 4))
        self.local_udp_port_var = tk.StringVar(value="0")
        ttk.Entry(top, textvariable=self.local_udp_port_var, width=7).grid(row=0, column=7, sticky="w", padx=(0, 10))
        ttk.Button(top, text="Connect / Open", command=self.connect_clicked).grid(row=0, column=9, padx=(0, 6))
        ttk.Button(top, text="Disconnect", command=self.disconnect_clicked).grid(row=0, column=10)
        options = ttk.Frame(self.root, padding=(10, 0, 10, 4))
        options.grid(row=1, column=0, sticky="ew")
        options.columnconfigure(5, weight=1)
        self.log_telemetry_var = tk.BooleanVar(value=False)
        self.log_raw_rx_var = tk.BooleanVar(value=False)
        ttk.Checkbutton(options, text="Log every telemetry frame", variable=self.log_telemetry_var).grid(row=0, column=0, sticky="w", padx=(0, 12))
        ttk.Checkbutton(options, text="Log raw RX packets", variable=self.log_raw_rx_var).grid(row=0, column=1, sticky="w", padx=(0, 12))
        self.status_var = tk.StringVar(value="Disconnected")
        ttk.Label(options, textvariable=self.status_var).grid(row=0, column=2, sticky="w", padx=(12, 0))
        self.counter_var = tk.StringVar(value="TX=0 RX=0 dropped=0 parse_errors=0 seq=0x00")
        ttk.Label(options, textvariable=self.counter_var).grid(row=0, column=5, sticky="e")

        ttk.Label(options, text="ADC VREF (V)").grid(row=1, column=0, sticky="e", padx=(0, 4), pady=(5, 0))
        self.adc_vref_var = tk.StringVar(value=f"{ADC_DEFAULT_VREF_VOLTS:g}")
        adc_vref_entry = ttk.Entry(options, textvariable=self.adc_vref_var, width=8)
        adc_vref_entry.grid(row=1, column=1, sticky="w", pady=(5, 0))
        adc_vref_entry.bind("<KeyRelease>", lambda _event: self.redraw_all_adc_plots())

        ttk.Label(options, text="ADC range").grid(row=1, column=2, sticky="e", padx=(12, 4), pady=(5, 0))
        self.adc_range_var = tk.StringVar(value="0..VREF (RANGE=0)")
        adc_range_combo = ttk.Combobox(
            options,
            textvariable=self.adc_range_var,
            values=list(ADC_RANGE_OPTIONS.keys()),
            state="readonly",
            width=20,
        )
        adc_range_combo.grid(row=1, column=3, sticky="w", pady=(5, 0))
        adc_range_combo.bind("<<ComboboxSelected>>", lambda _event: self.redraw_all_adc_plots())

        ttk.Label(options, text="Timestamp tick (ms)").grid(row=1, column=4, sticky="e", padx=(12, 4), pady=(5, 0))
        self.fpga_tick_ms_var = tk.StringVar(value="1.0")
        fpga_tick_entry = ttk.Entry(options, textvariable=self.fpga_tick_ms_var, width=8)
        fpga_tick_entry.grid(row=1, column=5, sticky="w", pady=(5, 0))
        fpga_tick_entry.bind("<KeyRelease>", lambda _event: self.redraw_all_adc_plots())

        self.conversion_hint_var = tk.StringVar()
        ttk.Label(options, textvariable=self.conversion_hint_var).grid(
            row=2, column=0, columnspan=6, sticky="w", pady=(4, 0)
        )
        self.update_conversion_hint()

        notebook = ttk.Notebook(self.root)
        notebook.grid(row=2, column=0, sticky="nsew", padx=10, pady=(4, 10))
        self.tabs["Spikeulike"] = TrafficTab(self, notebook, "Spikeulike", can_send=True)
        self.tabs["DAC"] = DacMainTab(self, notebook)
        self.tabs["ADC"] = AdcMainTab(self, notebook)
        self.tabs["HPU Core"] = HpuCoreTab(self, notebook)

    def get_adc_vref_volts(self) -> float:
        try:
            value = float(self.adc_vref_var.get().strip())
            if value <= 0.0:
                raise ValueError
            return value
        except Exception:
            return ADC_DEFAULT_VREF_VOLTS

    def get_adc_range_multiplier(self) -> float:
        return ADC_RANGE_OPTIONS.get(self.adc_range_var.get().strip(), 1.0)

    def get_adc_full_scale_voltage(self) -> float:
        return self.get_adc_vref_volts() * self.get_adc_range_multiplier()

    def adc_code_to_voltage(self, adc_code: int) -> float:
        return adc_code_to_voltage(
            adc_code,
            self.get_adc_vref_volts(),
            self.get_adc_range_multiplier(),
        )

    def get_fpga_timestamp_tick_seconds(self) -> float:
        try:
            tick_ms = float(self.fpga_tick_ms_var.get().strip())
            if tick_ms <= 0.0:
                raise ValueError
            return tick_ms / 1000.0
        except Exception:
            return FPGA_TIMESTAMP_DEFAULT_TICK_SECONDS

    def update_conversion_hint(self):
        if not hasattr(self, "conversion_hint_var"):
            return
        full_scale = self.get_adc_full_scale_voltage()
        lsb = full_scale / ADC_FULL_SCALE_COUNTS
        tick_ms = self.get_fpga_timestamp_tick_seconds() * 1000.0
        self.conversion_hint_var.set(
            f"ADC: voltage = code x {full_scale:g} / {ADC_FULL_SCALE_COUNTS}; "
            f"LSB={lsb * 1000.0:.6f} mV. Time: seconds = unwrapped_timestamp x {tick_ms:g} ms / 1000."
        )

    def redraw_all_adc_plots(self):
        self.update_conversion_hint()
        adc_main = self.tabs.get("ADC") if hasattr(self, "tabs") else None
        if isinstance(adc_main, AdcMainTab):
            for tab in adc_main.subtabs_by_source.values():
                tab.plot_dirty = True
                tab.redraw_plot(force=True)

    def connect_clicked(self):
        if self.sock is not None:
            messagebox.showinfo("Already connected", "Disconnect first.")
            return
        mode = self.mode_var.get().strip().upper()
        ip = self.ip_var.get().strip()
        try:
            port = int(self.port_var.get().strip(), 10)
            if not 0 <= port <= 65535:
                raise ValueError
        except ValueError:
            messagebox.showerror("Port error", "Port must be 0..65535.")
            return
        if mode == "UDP":
            self._open_udp(ip, port)
        elif mode == "TCP":
            self._open_tcp(ip, port)
        else:
            messagebox.showerror("Mode error", f"Unsupported mode: {mode}")

    def _open_udp(self, ip: str, port: int):
        try:
            local_port = int(self.local_udp_port_var.get().strip(), 10)
            if not 0 <= local_port <= 65535:
                raise ValueError
        except ValueError:
            messagebox.showerror("UDP local port error", "Local UDP port must be 0..65535. Use 0 for automatic.")
            return
        s = None
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind(("0.0.0.0", local_port))
            s.connect((ip, port))
            s.settimeout(0.02)
            self.start_network_thread(s, "UDP")
            actual_ip, actual_port = s.getsockname()
            self.status_var.set(f"UDP open: PC:{actual_port} -> {ip}:{port}")
            self.log_global(f"[{now_stamp()}] UDP open. Local={actual_ip}:{actual_port}, Remote={ip}:{port}")
        except Exception as exc:
            if s is not None:
                try:
                    s.close()
                except Exception:
                    pass
            messagebox.showerror("UDP open error", str(exc))
            self.status_var.set("Disconnected")

    def _open_tcp(self, ip: str, port: int):
        s = None
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.settimeout(3.0)
            s.connect((ip, port))
            s.settimeout(0.02)
            self.start_network_thread(s, "TCP")
            self.status_var.set(f"TCP connected: {ip}:{port}")
            self.log_global(f"[{now_stamp()}] TCP connected to {ip}:{port}")
        except Exception as exc:
            if s is not None:
                try:
                    s.close()
                except Exception:
                    pass
            messagebox.showerror("TCP connection error", str(exc))
            self.status_var.set("Disconnected")

    def start_network_thread(self, s: socket.socket, mode: str):
        self.rx_stop.clear()
        self.rx_buffer.clear()
        self.sock = s
        self.active_mode = mode
        self.rx_thread = threading.Thread(target=self.network_loop, args=(s, mode), daemon=True)
        self.rx_thread.start()

    def disconnect_clicked(self):
        self.disconnect()

    def disconnect(self):
        self.rx_stop.set()
        s = self.sock
        mode = self.active_mode
        self.sock = None
        self.active_mode = None
        if s is not None:
            if mode == "TCP":
                try:
                    s.shutdown(socket.SHUT_RDWR)
                except Exception:
                    pass
            try:
                s.close()
            except Exception:
                pass
        self.status_var.set("Disconnected")
        if mode:
            self.log_global(f"[{now_stamp()}] {mode} closed")

    def queue_packet_for_send(self, packet: bytes, tab_name: str):
        if self.sock is None or self.active_mode is None:
            raise RuntimeError("Not connected/open.")
        try:
            self.tx_queue.put_nowait(packet)
        except queue.Full:
            raise RuntimeError("TX queue is full.")
        self.log_global(f"[{now_stamp()}] TX queued from {tab_name}: {bytes_to_hex(packet)}")
        self.pack_seq = (self.pack_seq + 1) & 0xFF

    def network_loop(self, s: socket.socket, mode: str):
        while not self.rx_stop.is_set():
            while True:
                try:
                    pkt = self.tx_queue.get_nowait()
                except queue.Empty:
                    break
                try:
                    if mode == "TCP":
                        s.sendall(pkt)
                    else:
                        s.send(pkt)
                    self.tx_packets += 1
                except Exception as exc:
                    self.safe_queue_event(("disconnect", f"{mode} send failed: {exc}"))
                    return
            try:
                chunk = s.recv(4096)
                if not chunk and mode == "TCP":
                    self.safe_queue_event(("disconnect", "Remote TCP side closed the connection."))
                    return
                if chunk:
                    self.safe_queue_event(("data", chunk))
            except socket.timeout:
                continue
            except OSError:
                return
            except Exception as exc:
                self.safe_queue_event(("disconnect", f"{mode} receive error: {exc}"))
                return

    def safe_queue_event(self, event):
        try:
            self.rx_queue.put_nowait(event)
        except queue.Full:
            self.dropped_rx_packets += 1

    def process_rx_queue(self):
        processed = 0
        try:
            while processed < MAX_PACKETS_PER_UI_TICK:
                kind, payload = self.rx_queue.get_nowait()
                processed += 1
                if kind == "data":
                    self.rx_packets += 1
                    self.handle_rx_bytes(payload)
                elif kind == "disconnect":
                    self.log_global(f"[{now_stamp()}] {payload}")
                    self.disconnect()
        except queue.Empty:
            pass
        finally:
            self.root.after(UI_QUEUE_INTERVAL_MS, self.process_rx_queue)

    def handle_rx_bytes(self, data: bytes):
        if self.log_raw_rx_var.get():
            self.log_global(f"[{now_stamp()}] RX raw: {bytes_to_hex(data)}")
        if self.active_mode == "UDP":
            parsed = self.try_parse_exact_datagram(data)
            if parsed is None:
                self.parse_errors += 1
                self.log_global(f"[{now_stamp()}] UDP unparsed datagram: {bytes_to_hex(data)}")
            else:
                self.route_packet(parsed, data)
            return
        self.rx_buffer.extend(data)
        if len(self.rx_buffer) > RECV_BUFFER_LIMIT:
            self.parse_errors += 1
            self.log_global(f"[{now_stamp()}] RX buffer overflow; clearing.")
            self.rx_buffer.clear()
            return
        while self.rx_buffer:
            parsed = self.try_parse_from_stream(self.rx_buffer)
            if parsed is None:
                break
            if parsed == "discard_one":
                bad = self.rx_buffer.pop(0)
                self.parse_errors += 1
                self.log_global(f"[{now_stamp()}] Discarded unsynchronized byte: {bad:02X}")
                continue
            pkt = parsed
            raw = bytes(self.rx_buffer[:pkt.total_len])
            del self.rx_buffer[:pkt.total_len]
            self.route_packet(pkt, raw)

    def try_parse_exact_datagram(self, data: bytes):
        candidates = self.packet_candidates(data)
        exact = [c for c in candidates if c.total_len == len(data)]
        if not exact:
            return None
        for candidate in exact:
            if candidate.kind == "TM":
                return candidate
        return exact[0]

    def try_parse_from_stream(self, buf: bytearray):
        if not buf:
            return None
        if buf[0] != VERSION:
            return "discard_one"
        candidates = self.packet_candidates(bytes(buf))
        complete = [c for c in candidates if len(buf) >= c.total_len]
        if not complete:
            return None
        for candidate in complete:
            if candidate.kind == "TM":
                return candidate
        return complete[0]

    def packet_candidates(self, data: bytes):
        if not data or data[0] != VERSION:
            return []
        out = []
        if len(data) >= TC_HEADER_BYTES:
            source = data[2]
            length_field = data[3]
            payload_len = payload_size_from_length(length_field)
            total = TC_HEADER_BYTES + payload_len
            if source in TAB_BY_SOURCE and total <= len(data):
                out.append(ParsedPacket("TC_ECHO", total, source, data[TC_HEADER_BYTES:total], {"seq": data[1], "len": length_field, "payload_len": payload_len, "source_label": SOURCE_LABEL_BY_VALUE.get(source, f"0x{source:02X}")}))
        if len(data) >= TM_HEADER_BYTES:
            source = data[4]
            length_field = data[5]
            payload_len = payload_size_from_length(length_field)
            total = TM_HEADER_BYTES + payload_len
            if source in TAB_BY_SOURCE and total <= len(data):
                out.append(ParsedPacket("TM", total, source, data[TM_HEADER_BYTES:total], {"tel_seq": data[1], "time": (data[2] << 8) | data[3], "len": length_field, "payload_len": payload_len, "source_label": SOURCE_LABEL_BY_VALUE.get(source, f"0x{source:02X}")}))
        return out

    def route_packet(self, pkt: ParsedPacket, raw: bytes):
        source_label = pkt.meta.get(
            "source_label", SOURCE_LABEL_BY_VALUE.get(pkt.source, f"0x{pkt.source:02X}")
        )
        tab_name = TAB_BY_SOURCE.get(pkt.source, "HPU Core")

        if pkt.kind == "TM" and pkt.source == SOURCE_HPU:
            hpu = self.tabs.get("HPU Core")
            if isinstance(hpu, HpuCoreTab):
                hpu.receive_telemetry(raw, pkt.meta, pkt.payload)
                return

        if pkt.kind == "TM" and tab_name == "ADC":
            adc_main = self.tabs.get("ADC")
            if isinstance(adc_main, AdcMainTab):
                adc_tab = adc_main.get_tab_for_source(pkt.source)
                if adc_tab is not None:
                    adc_tab.receive_telemetry(raw, pkt.meta, pkt.payload)
                    return

        if pkt.kind == "TC_ECHO":
            line = (
                f"[{now_stamp()}] RX {self.active_mode or ''} TC echo | "
                f"SEQ=0x{pkt.meta['seq']:02X}, SOURCE=0x{pkt.source:02X} ({source_label}), "
                f"LEN=0x{pkt.meta['len']:02X}, RAW={bytes_to_hex(raw)} | DATA={bytes_to_hex(pkt.payload)}"
            )
        else:
            line = (
                f"[{now_stamp()}] RX {self.active_mode or ''} telemetry | "
                f"TEL_SEQ=0x{pkt.meta['tel_seq']:02X}, TIME=0x{pkt.meta['time']:04X}, "
                f"SOURCE=0x{pkt.source:02X} ({source_label}), LEN=0x{pkt.meta['len']:02X}, "
                f"RAW={bytes_to_hex(raw)} | DATA={bytes_to_hex(pkt.payload)}"
            )

        target = self.tabs.get(tab_name, self.tabs.get("HPU Core"))
        if pkt.source == SOURCE_HPU and isinstance(target, HpuCoreTab):
            target.receive_echo(line)
            return
        if hasattr(target, "append_rx"):
            target.append_rx(line)
        if pkt.kind == "TM" and tab_name != "HPU Core":
            hpu = self.tabs.get("HPU Core")
            if hasattr(hpu, "append_rx"):
                hpu.append_rx(line)

    def set_adc_active_channels(self, source_id: int, channels: list[int]):
        self.adc_active_channels[source_id] = list(channels)

    def get_adc_active_channels(self, source_id: int) -> list[int]:
        return list(self.adc_active_channels.get(source_id, []))

    def log_global(self, line: str):
        hpu = self.tabs.get("HPU Core")
        if hasattr(hpu, "append_rx"):
            hpu.append_rx(line)

    def flush_all_logs(self):
        for tab in self.tabs.values():
            if hasattr(tab, "flush_pending_logs"):
                tab.flush_pending_logs()
        self.root.after(LOG_FLUSH_INTERVAL_MS, self.flush_all_logs)

    def redraw_dirty_plots(self):
        adc_main = self.tabs.get("ADC")
        if isinstance(adc_main, AdcMainTab):
            adc_main.redraw_dirty_plots()
        hpu = self.tabs.get("HPU Core")
        if isinstance(hpu, HpuCoreTab):
            hpu.redraw_plot(force=False)
        self.root.after(PLOT_REFRESH_INTERVAL_MS, self.redraw_dirty_plots)

    def update_counters(self):
        self.counter_var.set(f"TX={self.tx_packets} RX={self.rx_packets} dropped={self.dropped_rx_packets} parse_errors={self.parse_errors} seq=0x{self.pack_seq:02X} queue={self.rx_queue.qsize()}")
        self.root.after(500, self.update_counters)

    def on_close(self):
        self.disconnect()
        self.root.destroy()


def main():
    root = tk.Tk()
    EthernetGuiApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()