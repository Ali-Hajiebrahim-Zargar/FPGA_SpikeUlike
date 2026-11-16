# Mercury XU5 / PE1: Timestamp V3 + UART-off + Qt6 GUI

Integration branch: update/xu5-timestamp-v3-qt6-uart-off-20261116, based on main (2026-11-16).

## Confirmed configuration
- AMD Vivado/Vitis 2025.1. UDP board 192.168.1.50:5001. GEM0 KSZ9031RNX MDIO3.
- Command DMA 0x80020000, telemetry DMA 0x80040000, Spike programmer 0x80030000.
- Telemetry V3 header 8 bytes, 32-bit big-endian FPGA timestamps with 1-us tick; legacy V1 16-bit 1-ms supported. Telecommands V1/V2 unchanged.
- Qt6/MinGW GUI compiled on Windows and protocol compatibility test passed (1/1). Throughput and UART silence on real hardware remain untested.

## New Boot image provenance
- Built with Bootgen 2025.1 from FSBL ELF, Timestamp V3 FPGA bitstream and A53 bare-metal lwIP application ELF; NO QEMU PMUFW, BL31, or U-Boot.
- New test boot LOCAL ONLY before Windows sync:
  C:\xu5\exports\SD_BOOT_TIMESTAMP_V3_UART_OFF_TEST_20261114_122558\BOOT.BIN
- Expected SHA-256: B4AAB46FD459E4A9FB3A96BE7F6241C44B65090F999963F7367645BAF20C28CF
- Never replace golden: C:\xu5\exports\SD_BOOT_SPIKE3371_20261023_172702\BOOT.BIN
- Golden SHA-256: F7F923C492189299F45C1EDEDD88A4F769400B870209B16526C6765FCB7210AB
- Pre-test SD backup: C:\xu5\exports\SD_BOOT_BACKUP_20261116_113440\BOOT.BIN

## Publishing/rebuild requirements
- Existing Vivado/Mercury_XU5_export.tcl in main represents a legacy design with FPGA_TIMESTAMP_TIMER_16, not full current Timestamp V3. Run the new Vivado/export_current_project.tcl against the actual Windows XPR to generate project_rebuild.tcl, block_designs/*.tcl and vivado_source_archive.zip (source-only).
- The Qt6 GUI, Python GUI v4, current Vitis workspace source/metadata and exact BOOT.BIN/ELFs/bitstream/XSA are present only in uploaded package or on the Windows development PC. They must be copied and committed by the supplied Windows sync script. Do not claim these files were uploaded until verified in GitHub.
- Vitis app and FSBL BSP standalone_stdout were set to None. The final UART-off build changed the EXISTING UARTPS BSP outbyte(char) to a no-op (void)c; adding a second outbyte causes multiple-definition link errors. BSP regeneration can undo this change; hardware/BootROM UART effects are unverified.
- Do not overwrite main, old HDL sources or golden BOOT.BIN. Check licenses before public redistribution of generated/vendor IP/bitstreams.

## Validation status
Build: successful (FSBL, app, Bootgen, C++ GUI, 1/1 protocol tests). Full current Vivado/Vitis export and real hardware runtime validation: pending. GitHub upload of binary/test artifacts: pending Windows sync.
