# Mercury XU5 / Mercury+ PE1 — Native C++/Qt real-time TC/TM GUI

A **source-code C++17 port** of the Python `mercury_xu5_realtime_gui_v4.py` workflow, targeting **Windows x64** and Mercury XU5/PE1's bare-metal FPGA Ethernet application (`192.168.1.50:5001`). It does **not** change `BOOT.BIN`, the firmware, FPGA bitstream, hardware configuration, or wire protocol.

**Validation status**: the standard-library C++ protocol/capture core was built and tested on Linux with GCC; **the Qt6 GUI has not been compiled or hardware-tested in the author's environment because Qt developer libraries are unavailable there**. Build and validate the complete application on your Windows machine before using it as a replacement for the established Python GUI.

## Why native C++ helps

- Qt `QUdpSocket` / `QTcpSocket` network I/O and protocol decoding run in a **dedicated QThread** with its own event loop; there is no per-received-ADC-frame cross-thread UI signal.
- Thread-safe per-ADC sample rings retain up to **250,000 received values per channel**. ADC capture is independent of painting, so a slow UI redraw does not intentionally drop ADC data.
- Each 128-sample block creates a persistent **min/max envelope**. Full-history plots inspect roughly 4,000 extrema points per channel rather than scanning all 250,000 samples at each frame. Recent view uses actual raw samples.
- `QPainter` draws plots without matplotlib overhead; nominal UI update period is **50 ms** (target up to 20 FPS, not a real-time deadline).
- HPU rate uses persistent 0.5-second bins, avoiding a 250,000-event scan on every GUI repaint.
- Time axes use real **FPGA V3 32-bit / 1-us** timestamps, including wrap unwrapping, not synthetic time interpolation.

**Limits remain:** the FPGA timestamp quantization is 1 microsecond; insufficient ADC sample rate causes aliasing; Ethernet/UDP/lwIP/kernel socket buffers can still lose packets; GUI frame rate is not the ADC sample rate; memory rings evict old samples when full. Running a C++ GUI cannot solve any of these fundamental constraints. **V3 has one time per received telemetry frame; samples carried by that frame share the same time.** For high-frequency verification, compare against an oscilloscope and check acquisition sample rate, timestamp gaps, and actual network traffic.

## Included functions

| Area | C++ implementation |
|---|---|
| Ethernet | UDP and TCP, configurable board/remote/local ports, background thread |
| TC V1 | `01 SEQ SOURCE (LEN-1) DATA`, 1–256 payload bytes |
| Spikeulike V2 | `02 SEQ 00 LEN_MSB LEN_LSB DATA`, 257–422 bytes |
| TM V1 | 16-bit legacy timestamp, 6-byte header |
| TM V3 | 32-bit timestamp, 8-byte header, source ID, actual ADC triples |
| DAC1–4 | Sine/Cosine/Pulse/Triangle, 1–125 samples/cycle, period ticks, channel flags, start/stop mask |
| ADC1–4 | Six pair-enable bits, 12 channels, grid and single live/full plots, zoom, VREF/RANGE |
| ADC3 model | Exact 64-entry LUT, active-pair phase advance, DOUTB 90-degree offset; phase-fitting overlay in recent view |
| HPU | 42-register table, raw reads/writes, project configuration, automatic polls, event table, histogram/rate, CSV/raw32 export |
| Diagnostics | RX packets/s, parse errors, filtered packets, 8-bit per-source sequence discontinuities, bounded logs |

Differences from the Python version: the UI has a different Qt layout, box zoom is native drag/scroll, the HPU histogram is represented by a line through 512 address counts rather than a bar chart, and there are no identical Tkinter widgets. The high-rate path does **not** produce a lossless file recording. Per-source sequence skips can also be caused by **interleaving of several telemetry sources if the firmware uses a global sequence counter**; do not interpret this diagnostic by itself as an exact UDP loss count.

## Build on Windows 10/11 (x64)

**Prerequisites:**

1. **Visual Studio 2022 with Desktop development with C++**, including the MSVC x64 compiler.
2. **Qt 6.5 or newer**, selecting the **MSVC 2022 64-bit** kit (Qt Widgets and Qt Network).
3. CMake (from Visual Studio, the Qt installer, or standalone), with `cmake.exe` and `ctest.exe` available in PowerShell.

Download and extract the project ZIP to any directory that is **not** your Vitis workspace. In PowerShell, enter that directory and run:

```powershell
.\build-windows.ps1
```

If Qt is not under `C:\Qt`, specify its exact kit path:

```powershell
.\build-windows.ps1 -QtRoot "C:\Qt\6.12.0\msvc2022_64"
```

The script configures CMake for MSVC 2022 x64, builds the GUI and core tests, runs the tests, and calls `windeployqt` if available. Expected executable:

```text
build\bin\Release\Mercury_XU5_GUI.exe
```

Check the script's actual `GUI_EXE` output for the verified location. If CMake compilation reports an error, **do not use** the unverified GUI until corrected. The current Python GUI remains the tested operational fallback.

### Test the C++ core without Qt (Linux/macOS or Windows with CMake)

```sh
cmake -S . -B build-core -DXU5_BUILD_GUI=OFF -DCMAKE_BUILD_TYPE=Release
cmake --build build-core
ctest --test-dir build-core --output-on-failure
./build-core/xu5_core_benchmark 250000
```

This benchmark exercises the in-memory protocol decoder and ADC ring only, **not** UDP, Qt painting, disk storage, real-world packet timing, or hardware throughput. No end-to-end performance improvement is claimed until measured on the target machine.

## First board test — conservative procedure

1. Use the existing known-working, backed-up SD image; **no firmware or BOOT.BIN update is needed**.
2. Connect with **UDP** / board `192.168.1.50` / port `5001` / local UDP port `0`. Never run Python and C++ receivers simultaneously while comparing telemetry: their different local ports and board reply handling can complicate interpretation.
3. Select one ADC pair, send the ADC command, and open the corresponding single-channel recent plot. Compare to the Python GUI at the same FPGA conditions.
4. Repeat at increasing frequencies, confirming that **the actual ADC sample rate**, not just plot FPS, is high enough for the desired waveform. Observe if time stamps repeat or skip, and whether `parse errors` or OS-level UDP drops occur.
5. Compare DAC output against a physical oscilloscope and check HPU reads/writes before relying on the C++ version in a test or experiment.
6. Leave both **Log every telemetry frame** and **Log raw RX packets** disabled for high-rate tests. Enabling them has deliberately expensive per-packet string formatting and bounded logs.

## Technical files

- `src/protocol.hpp` — dependency-free C++ packet encoders/decoders and DAC sample generation.
- `src/capture.hpp` — thread-safe ADC/HPU acquisition, timestamp expansion, rings, persistent peak envelope, bounded logs and counters.
- `src/hpu_regs.hpp` — register map transcribed from the supplied Python GUI.
- `src/main.cpp` — Qt6 UI, native plots and background socket worker.
- `tests/test_protocol.cpp` — deterministic protocol/capture assertions.
- `tests/bench_core.cpp` — synthetic CPU benchmark.
- `build-windows.ps1`, `CMakeLists.txt` — Windows CMake/Qt build.

Official Qt references: [Qt6 QUdpSocket](https://doc.qt.io/qt-6/qudpsocket.html), [Qt thread-affinity rules](https://doc.qt.io/qt-6/threads-qobject.html), [Qt6 CMake CLI](https://doc.qt.io/qt-6/cmake-build-on-cmdline.html).
