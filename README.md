# FPGA SpikeUlike - Mercury XU5 / PE1 Ethernet Control and Telemetry

This repository is a source snapshot of the current FPGA + Vitis + Python GUI system used on an **Enclustra Mercury XU5 (ME-XU5-5EV-2I-D12E)** mounted on a **Mercury+ PE1** carrier.

The system provides a PC-to-FPGA Ethernet command path and an FPGA-to-PC telemetry path for:

- SpikeUlike serial programming
- 4 x DAC8568 control paths
- 4 x AD7266 acquisition paths
- ADC3 behavioral sine-wave test model
- HPU Core register control and Auxiliary PAER event reception
- Live Python GUI plotting, logging, export, and HPU control

The validated development tool version is **AMD Vivado/Vitis 2025.1** and the FPGA part is:

```text
xczu5ev-sfvc784-2-i
```

## Upstream designs pinned for this project

The work was developed on top of these exact upstream revisions:

- Enclustra Mercury XU5 PE1 reference design:  
  https://github.com/enclustra/Mercury_XU5_PE1_Reference_Design/tree/e0be68be701cb4f48b0fc043bb6f7fcc881499e3
- IIT HPU Core:  
  https://github.com/event-driven-robotics/HPU_Core/tree/c4599a5f6c438788329e034e389e806f71ab9554

Use those revisions when reproducing the design.

---

# Repository layout

```text
FPGA_SpikeUlike/
|
|-- GUI/
|   `-- ethernet_tc_tm_gui.py
|
|-- Vivado/
|   |-- Mercury_XU5_export.tcl
|   |-- src_snapshot.rar
|   |-- src_snapshot_manifest.txt
|   |-- src/
|   |   |-- axis_cmd_packet_router.vhd
|   |   |-- axis_spike_programmer.vhd
|   |   |-- axis_hpu_control_bridge.vhd
|   |   `-- axis_hpu_telemetry_adapter.vhd
|   |-- constraints/
|   |   |-- spike_programmer_pins.xdc
|   |   `-- hpu_aux_paer.xdc
|   `-- reports/
|       `-- all_constraints_dump.xdc
|
|-- Vitis/
|   |-- boot_image.bif
|   |-- platform-vitis-comp.json
|   `-- lwip_echo_server/
|       |-- vitis-comp.json
|       `-- src/
|           |-- echo.c
|           |-- main.c
|           |-- platform*.c/.h
|           |-- CMakeLists.txt
|           |-- UserConfig.cmake
|           |-- app.yaml
|           |-- lscript.ld
|           `-- other lwIP example support sources
|
`-- README.md
```

`Vivado/src_snapshot.rar.b64` is a Base64-encoded copy of the full captured custom `src` archive. Decode it back to `src_snapshot.rar` before extracting it. Its content is listed in `Vivado/src_snapshot_manifest.txt`. The most important integration modules are additionally present as normal text files under `Vivado/src/` so that they can be reviewed directly on GitHub.

Generated Vivado/Vitis outputs such as `.bit`, `.xsa`, `.elf`, `BOOT.BIN`, `.runs`, generated BSPs, and build directories are intentionally not version controlled. They are reproducible build products and are excluded by `.gitignore`.

---

# 1. System architecture

The command path is:

```text
Python GUI
   |
   | UDP / Ethernet
   v
Zynq MPSoC / lwIP application
   |
   | AXI DMA MM2S
   v
axis_cmd_packet_router
   |
   +--> 0x00  axis_spike_programmer
   +--> 0x01  DAC1
   +--> 0x02  DAC2
   +--> 0x03  DAC3
   +--> 0x04  DAC4
   +--> 0x05  ADC1
   +--> 0x06  ADC2
   +--> 0x07  ADC3
   +--> 0x08  ADC4
   `--> 0x09  axis_hpu_control_bridge --> HPU Core AXI-Lite
```

The telemetry path is:

```text
ADC telemetry / HPU events and responses
   |
   v
axis_telemetry_data_manager
   |
   | AXI Stream
   v
Telemetry AXI DMA S2MM
   |
   v
Vitis lwIP application
   |
   | UDP
   v
Python GUI
```

The design uses a **100 MHz PL clock** for the custom logic.

---

# 2. Ethernet protocol

The FPGA command router expects one AXI4-Stream frame per command packet.

## 2.1 Command packet format

```text
BYTE 0 : VERSION
BYTE 1 : PACKET_SEQ
BYTE 2 : SOURCE_ID
BYTE 3 : DATA_LENGTH_MINUS_ONE
BYTE 4.. : DATA
```

Current version:

```text
VERSION = 0x01
```

The length field is encoded as:

```text
payload length = DATA_LENGTH_MINUS_ONE + 1
```

Therefore the maximum payload supported by the current command format is 256 bytes and the largest complete packet is 260 bytes.

## 2.2 Source IDs

| Source | ID |
|---|---:|
| SpikeUlike | `0x00` |
| DAC1 | `0x01` |
| DAC2 | `0x02` |
| DAC3 | `0x03` |
| DAC4 | `0x04` |
| ADC1 | `0x05` |
| ADC2 | `0x06` |
| ADC3 | `0x07` |
| ADC4 | `0x08` |
| HPU Core | `0x09` |

The router removes the four-byte outer header. Only the `DATA` bytes are presented to the selected peripheral module.

---

# 3. Telemetry format

Telemetry frames use a six-byte header:

```text
BYTE 0 : VERSION
BYTE 1 : TELEMETRY_SEQUENCE
BYTE 2 : TIMESTAMP_MSB
BYTE 3 : TIMESTAMP_LSB
BYTE 4 : SOURCE_ID
BYTE 5 : DATA_LENGTH_MINUS_ONE
BYTE 6.. : DATA
```

The timestamp is a 16-bit FPGA frame timestamp. The GUI unwraps it and reconstructs a monotonic time axis for plotting.

The Vitis telemetry DMA is armed with a maximum-size receive buffer and uses `TLAST` to terminate each variable-length telemetry frame.

The firmware remembers the most recent UDP client IP address and source port. Telemetry is sent to that endpoint.

---

# 4. SpikeUlike programmer

The SpikeUlike path is implemented by:

```text
Vivado/src/axis_spike_programmer.vhd
```

The router selects this block with:

```text
SOURCE_ID = 0x00
```

## 4.1 Default SpikeUlike configuration

```text
Input clock             = 100 MHz
Serial clock            = 1 MHz
Serial half-divider     = 50
Default chip bits       = 1024 bits
Marker byte             = 0xC5
Maximum payload bytes   = 1024
Maximum chip bits       = 65536
```

The default serial clock is generated as:

```text
100 MHz / (2 * 50) = 1 MHz
```

## 4.2 Programming data order

The programmer automatically inserts the marker byte. Do **not** add `0xC5` to the GUI payload.

Transmission order is:

```text
0xC5 marker
payload byte 0
payload byte 1
...
payload byte N-1
```

Bits inside every byte are shifted **LSB first**.

For marker `0xC5`, the physical bit sequence is:

```text
1 0 1 0 0 0 1 1
```

For the default 1024-bit chip configuration, use exactly 128 payload bytes.

The complete Ethernet command is therefore:

```text
01 <SEQ> 00 7F <128 payload bytes>
```

because:

```text
128 - 1 = 127 = 0x7F
```

A useful logic-analyzer test payload is 128 bytes alternating between `AA` and `55`.

## 4.3 Serial control signals

Idle state:

```text
ENABLE = 1
LATCH  = 1
CLK    = 0
DATA   = 0
```

During programming:

```text
ENABLE = 0
LATCH  = 0
CLK    = 1 MHz serial clock
DATA   = marker followed by payload bits
```

At 128 payload bytes, the transfer contains:

```text
8 marker bits + 1024 payload bits = 1032 clock cycles
```

At 1 MHz this takes approximately:

```text
1.032 ms
```

The programmer samples `CHIP_Q` for eight bits beginning at chip bit index 1024. Successful readback requires the returned byte to equal the marker `0xC5`.

## 4.4 SpikeUlike AXI-Lite register map

| Offset | Register | Notes |
|---:|---|---|
| `0x00` | CONTROL | bit0 enable, bit1 clear status pulse, bit2 abort pulse |
| `0x04` | STATUS | busy/done/success/error/overflow/readback-valid |
| `0x08` | SERIAL_DIV_HALF | serial clock half-period divider |
| `0x0C` | CHIP_BITS | chip shift-register length |
| `0x10` | MARKER_BYTE | default `0xC5` |
| `0x14` | READBACK_BYTE | last eight readback bits |
| `0x18` | PAYLOAD_BYTES | received payload byte count |
| `0x1C` | TOTAL_SHIFT_BITS | total serial shift count |

STATUS bits:

```text
bit 0 = BUSY
bit 1 = DONE
bit 2 = SUCCESS
bit 3 = ERROR
bit 4 = PAYLOAD_OVERFLOW
bit 5 = READBACK_VALID
```

## 4.5 SpikeUlike FPGA pins

All SpikeUlike pins use `LVCMOS18`.

| Signal | FPGA package pin |
|---|---|
| `SPIKE_CHIP_CLK` | `AF13` |
| `SPIKE_CHIP_DATA` | `AE15` |
| `SPIKE_CHIP_LATCH` | `W12` |
| `SPIKE_CHIP_ENABLE` | `AE14` |
| `SPIKE_CHIP_Q` | `L7` |
| `SPIKE_SUCCESS_LED` | `P9` |

For oscilloscope/logic-analyzer debugging, probe at least:

```text
CH1 = SPIKE_CHIP_CLK
CH2 = SPIKE_CHIP_DATA
CH3 = SPIKE_CHIP_LATCH
CH4 = SPIKE_CHIP_ENABLE
CH5 = SPIKE_CHIP_Q       (when available)
```

A useful trigger is the falling edge of `SPIKE_CHIP_ENABLE`.

---

# 5. HPU Core integration

The HPU Core is used only for event reception and register control in the current architecture.

The intended command path is:

```text
GUI
 -> SOURCE_ID 0x09
 -> axis_cmd_packet_router
 -> axis_hpu_control_bridge
 -> HPU Core S_AXI
```

The HPU AXI-Stream command input is not used. GUI-generated events are not injected into the HPU.

Auxiliary PAER reception is enabled and HPU events are returned through the common telemetry path.

## 5.1 HPU command payloads

### AXI-Lite write request

```text
0x01 | ADDRESS | WSTRB | RESERVED | DATA[31:24] | DATA[23:16] | DATA[15:8] | DATA[7:0]
```

### AXI-Lite read request

```text
0x02 | ADDRESS
```

The outer command packet still uses source ID `0x09`.

## 5.2 HPU responses

```text
0x81 = write response
0x82 = read response
0xE0 = protocol/error response
0x40 = HPU event payload type
```

An HPU event telemetry payload is:

```text
0x40 + 4-byte event word
```

With the six-byte telemetry header, one HPU event frame is 11 bytes.

## 5.3 HPU runtime configuration used by the GUI

The GUI configuration button writes:

```text
RX_CNFG  (0x48) = 0x02000100
AUX_CTRL (0x60) = 0x00000002
CTRL     (0x00) = 0x00002002
```

This enables the Auxiliary PAER path and the receive/event streaming configuration used in the project.

Current PAER data width:

```text
C_PAER_DSIZE = 9
```

Current PAER assumptions:

```text
REQ active low
ACK active low
sample delay = 1
ACK set       = 0
ACK release   = 2
```

## 5.4 HPU Auxiliary PAER pins

All use `LVCMOS18`.

```text
ADDR[0] = B1
ADDR[1] = C1
ADDR[2] = A1
ADDR[3] = A2
ADDR[4] = A4
ADDR[5] = B4
ADDR[6] = A8
ADDR[7] = A9
ADDR[8] = D9
REQ     = E9
ACK     = F7
```

---

# 6. AD7266 acquisition and ADC3 behavioral model

The current ADC3 test configuration can use a behavioral model instead of a physical AD7266 input.

The model in the captured Vivado source snapshot uses a 64-entry, 12-bit sine lookup table.

Current model parameters are:

```text
LUT length             = 64 samples
phase step             = 1 LUT entry / conversion
pair phase offset      = 3 LUT entries
DOUTB phase offset     = 16 LUT entries
```

A 16-entry offset corresponds to 90 degrees for a 64-entry LUT.

The Python GUI contains the exact same 64-value LUT so received ADC3 samples can be compared against the expected model sequence.

ADC telemetry payloads are decoded as two channel/value triplets:

```text
CHANNEL_A | SAMPLE_A_MSB | SAMPLE_A_LSB |
CHANNEL_B | SAMPLE_B_MSB | SAMPLE_B_LSB
```

The AD7266 sample is treated as a 12-bit code.

Default GUI conversion uses:

```text
VREF = 2.5 V
resolution = 12 bits
```

The GUI also supports the AD7266 range selection for `0..VREF` and `0..2*VREF` scaling.

---

# 7. Python GUI

Run:

```text
GUI/ethernet_tc_tm_gui.py
```

The GUI is written with Tkinter and Matplotlib.

Install the non-standard dependency with:

```bash
python -m pip install matplotlib
```

Tkinter must also be available in the Python installation.

## 7.1 Default connection

```text
Board IP = 192.168.1.50
UDP port = 5001
```

The current FPGA/Vitis firmware is UDP based. The GUI contains transport abstractions, but the validated firmware path is UDP.

## 7.2 GUI capabilities

The current GUI includes:

- SpikeUlike command construction
- DAC command generation
- ADC command/configuration controls
- HPU AXI-Lite register browser
- HPU register read/write operations
- HPU runtime configuration button
- HPU event decoding and recent-event table
- HPU 9-bit address histogram
- HPU event-rate graph
- ADC live plotting
- cumulative ADC history
- history-preserving plot compaction
- persistent rectangle/box zoom
- `Open selected` live capture
- CSV export
- HPU raw 32-bit binary export
- raw log saving

## 7.3 ADC time axis

The FPGA telemetry timestamp is coarse relative to the ADC frame rate, so several consecutive ADC frames can carry the same timestamp.

Plotting those raw timestamps directly produces vertical clusters and an incorrect waveform. The current GUI therefore:

1. unwraps the 16-bit FPGA timestamp,
2. uses real timestamp changes as time anchors,
3. preserves telemetry frame ordering,
4. reconstructs uniform sample locations between those anchors,
5. displays the x-axis in seconds rather than sample number.

This preserves a physically meaningful time axis while avoiding false vertical line segments caused by repeated frame timestamps.

## 7.4 Plot history and zoom

The GUI retains up to:

```text
250000 ADC values per channel
```

For responsive rendering, long histories are compacted while preserving extrema.

The main ADC grid and selected-channel window support persistent box zoom. A user-selected zoom region is not automatically lost when new live samples arrive.

---

# 8. Vitis application

The current application is under:

```text
Vitis/lwip_echo_server/
```

Validated target domain:

```text
standalone_psu_cortexa53_0
```

Validated Vitis workspace on the development machine:

```text
C:\vitis_dac8568
```

The final hardware platform was exported as:

```text
C:\vitis_dac8568\Mercury_XU5_HPU.xsa
```

The application ELF was built as:

```text
C:\vitis_dac8568\lwip_echo_server\build\lwip_echo_server.elf
```

## 8.1 Network configuration

Validated runtime configuration:

```text
IP address = 192.168.1.50
Netmask    = 255.255.255.0
Gateway    = 192.168.1.1
UDP port   = 5001
```

The PHY was detected as a Micrel KSZ9031 at PHY address 3 and autonegotiated to 1000 Mb/s during the validated boot.

## 8.2 DMA roles

The validated design uses:

```text
Command DMA base   = 0x80020000
Spike programmer   = 0x80030000
Telemetry DMA base = 0x80040000
```

The command DMA transfers the complete Ethernet command packet to PL. The PL router consumes the first four header bytes and forwards only the payload.

The telemetry DMA is continuously re-armed to receive the next `TLAST`-terminated telemetry frame.

The firmware also echoes the received UDP command back to the PC before/while the PL command is processed. This is useful for confirming network transport independently from the peripheral response.

---

# 9. Vivado source snapshot

The original working project path was:

```text
C:\xu5\Mercury_XU5_PE1_Reference_Design\Vivado\ME-XU5-5EV-2I-D12E\Mercury_XU5_PE1.xpr
```

The source archive:

```text
Vivado/src_snapshot.rar.b64
```

contains the captured custom `src` directory including:

- `ad7266_axis_driver.vhd`
- `ad7266_spi_sine_model.vhd`
- `axis_cmd_packet_router.vhd`
- `axis_dac8568_packet_parser.vhd`
- `axis_dac8568_waveform_driver.vhd`
- `axis_spike_programmer.vhd`
- `axis_telemetry_data_manager.vhd`
- DAC8568 scheduler/frame/init/SPI/memory blocks
- `fpga_timestamp_timer_16.vhd`
- Enclustra GMII-to-RGMII support files
- reference-design top-level/timing files

The HPU-specific sources developed later are included separately under `Vivado/src/`:

```text
axis_hpu_control_bridge.vhd
axis_hpu_telemetry_adapter.vhd
```

The final HPU and SpikeUlike pin constraints are under `Vivado/constraints/`.

`Vivado/Mercury_XU5_export.tcl` is a Vivado 2025.1 block-design export from the development workspace. It requires the module-reference source files to be added before sourcing it. The source archive plus the HPU overlay files are therefore kept together in this repository.

---

# 10. Recommended reproduction procedure

## 10.1 Prepare the reference design

Clone the pinned Enclustra revision:

```bash
git clone https://github.com/enclustra/Mercury_XU5_PE1_Reference_Design.git
cd Mercury_XU5_PE1_Reference_Design
git checkout e0be68be701cb4f48b0fc043bb6f7fcc881499e3
```

Use the `ME-XU5-5EV-2I-D12E` target.

Decode `Vivado/src_snapshot.rar.b64` to `src_snapshot.rar`, extract it, and overlay its `src` content onto the reference-design `src` directory.

Then copy the readable HPU integration sources and constraints from this repository into the corresponding project source/constraint locations.

## 10.2 Install the HPU IP repository

Clone the exact HPU revision:

```bash
git clone https://github.com/event-driven-robotics/HPU_Core.git
git -C HPU_Core checkout c4599a5f6c438788329e034e389e806f71ab9554
```

Add that repository to the Vivado IP repository path and refresh the IP catalog.

Expected IP identification:

```text
IIT:IIT_lib:HPU_Core:4.0
```

## 10.3 Vivado

Use Vivado 2025.1.

The design clock used by the custom command/telemetry logic is 100 MHz.

The last validated implementation completed successfully with positive timing margin; the recorded WNS was approximately:

```text
WNS = +0.494 ns
```

No unrouted nets remained in the validated implementation.

Export the hardware platform after generating the bitstream.

The final XSA used by Vitis was named:

```text
Mercury_XU5_HPU.xsa
```

## 10.4 Vitis

Use Vitis 2025.1.

Create/update a platform from `Mercury_XU5_HPU.xsa`, targeting:

```text
psu_cortexa53_0
standalone
```

Use the application sources under:

```text
Vitis/lwip_echo_server/src/
```

The current `echo.c` is the HPU-capable version and should replace older lwIP example copies.

Build the application and verify that `lwip_echo_server.elf` is produced.

## 10.5 Boot image

`Vitis/boot_image.bif` documents the final three partitions:

```text
FSBL
PL bitstream
lwip_echo_server.elf
```

The paths in a BIF are machine-specific. Update them when the workspace is moved.

The validated final development paths were:

```text
FSBL:
C:/vitis_dac8568/platform/export/platform/sw/boot/fsbl.elf

Bitstream:
C:/xu5/Mercury_XU5_PE1_Reference_Design/Vivado/ME-XU5-5EV-2I-D12E/Mercury_XU5_PE1.runs/impl_1/Mercury_XU5_wrapper.bit

Application:
C:/vitis_dac8568/lwip_echo_server/build/lwip_echo_server.elf
```

---

# 11. microSD boot and UART

The validated SD boot switch configuration on the PE1 was:

```text
CFG A = [1 OFF, 2 OFF, 3 OFF, 4 ON]
CFG B = [1 OFF, 2 OFF, 3 ON, 4 OFF]
```

UART settings:

```text
115200 baud
8 data bits
no parity
1 stop bit
no flow control
```

A boot log may print:

```text
PMU-FW is not running, certain applications may not be supported.
```

That warning was observed in the validated setup and did not prevent the standalone Ethernet/DMA application from running.

Successful startup should include:

- command DMA initialized,
- telemetry DMA initialized and armed,
- Spike programmer initialized,
- lwIP initialized,
- KSZ9031 detected,
- link autonegotiation completed,
- IP `192.168.1.50` assigned,
- UDP server started on port `5001`.

---

# 12. Quick SpikeUlike network test

Connect the PC Ethernet interface to the same subnet as `192.168.1.50`.

Open the GUI and use:

```text
Host      = 192.168.1.50
Port      = 5001
Transport = UDP
Source    = SpikeUlike / 0x00
```

For a first 1024-bit logic-analyzer test, send 128 alternating bytes:

```text
AA 55 AA 55 AA 55 AA 55 ...
```

The resulting packet generated by the GUI must be:

```text
01 <SEQ> 00 7F <128 bytes>
```

Expected external behavior:

1. `ENABLE` falls low.
2. `LATCH` falls low.
3. `CLK` outputs approximately 1032 pulses at 1 MHz.
4. `DATA` starts with the LSB-first `0xC5` marker.
5. Payload follows LSB first within each byte.
6. `Q` is sampled for marker readback.
7. `ENABLE` and `LATCH` return high.
8. `SPIKE_SUCCESS_LED` is asserted only when readback equals `0xC5`.

---

# 13. Notes about generated files

Large/generated build outputs are intentionally excluded from Git because they are tool-version-specific and can be rebuilt from source:

```text
Vivado .runs/.gen/.cache
.bit / .bin / .xsa
Vitis platform export
Vitis build directory
.elf
BOOT.BIN
```

Keeping source, configuration, constraints, packet protocols, and exact upstream revisions in Git makes the project reviewable and reproducible without committing transient implementation products.

---

# 14. Current validated state summary

The source snapshot represents the development state in which:

- Ethernet UDP command reception works.
- Command packets are routed by source ID.
- SpikeUlike programming logic is integrated.
- DAC command paths are integrated.
- ADC telemetry is received and plotted.
- ADC3 can be driven by the 64-sample sine behavioral model.
- HPU register reads/writes are transported through source ID `0x09`.
- HPU Auxiliary PAER is configured for 9-bit event addresses.
- HPU events and register responses use the shared telemetry path.
- GUI ADC plots use FPGA frame time with reconstruction for repeated timestamps.
- GUI plot history is retained and compacted as it grows.
- GUI supports persistent box zoom.
- `Open selected` starts the selected ADC live view immediately.
- Vivado synthesis/implementation/bitstream generation completed successfully in the validated setup.
- Vitis standalone lwIP application built successfully.
- The board booted from microSD and established a 1 Gb/s Ethernet link.
