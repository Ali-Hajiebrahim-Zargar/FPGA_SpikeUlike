# Mercury XU5 Vivado Source Export

Vivado version: 2025.1
FPGA part: xczu5ev-sfvc784-2-i

Timestamp V3 uses a 32-bit timestamp counter and telemetry version 0x03.
The timer module retains the historical name FPGA_TIMESTAMP_TIMER_16.

project_rebuild.tcl and block_designs/*.tcl were exported from
the current Mercury_XU5_PE1.xpr project on 2026-11-16.

The source tree contains custom RTL and the constraints directory
contains project-local XDC/SDC files where available.

External HPU Core dependency:
https://github.com/event-driven-robotics/HPU_Core
Pinned revision: c4599a5f6c438788329e034e389e806f71ab9554

These files have not yet passed an independent clean-room
Vivado reconstruction test. The exported project Tcl may still
reference original Windows source paths and external IP repositories.

The Vivado archive operation failed due to Windows path-length
limitations. The generated Tcl scripts were completed before
that failure. Do not publish an incomplete source archive.

The BOOT.BIN bitstream provenance still requires verification.
