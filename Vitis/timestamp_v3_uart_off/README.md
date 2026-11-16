# Vitis 2025.1 UART-off / Timestamp V3 staging notes

Use the *actual* workspace \`C:\vitis_timestamp_v3\`; do not replace with the legacy \`C:\vitis_dac8568\` workspace archived under the repository's older \`Vitis/\` tree.

## Build on Windows

Run Vitis Python scripts that were used during the verified builds:

- \`C:\vitis_timestamp_v3\STEP228_build_platform.py\`
- \`C:\vitis_timestamp_v3\STEP228_build_app.py\`

Invoke each via:

    C:\Xilinx\2025.1\Vitis\bin\vitis.bat -s <script>

The staged copies of the actual app sources and scripts are uploaded from the Windows workspace by \`tools/stage_windows_artifacts.ps1\`.

## UART-off caveat

The successful FSBL and app build set \`standalone_stdout=None\` for both domains, and patched the *existing* source in each BSP UARTPS driver:

- \`platform\zynqmp_fsbl\zynqmp_fsbl_bsp\libsrc\uartps\src\xuartps_hw.c\`
- \`platform\psu_cortexa53_0\standalone_psu_cortexa53_0\bsp\libsrc\uartps\src\xuartps_hw.c\`

Replace only the body of \`void outbyte(char c)\` with a no-op \`(void)c;\` within the existing driver. Do not add another \`outbyte\` symbol to the app or FSBL (causes a linker multiple-definition error). This is a fragile generated-BSP change and can be lost after regeneration; check post-build symbols.

Do not distribute an edited copy of the vendor UART driver in the public repository without checking its license. Full boot-stage silence has not yet been proven on physical board.

## Bootgen

\`Boot/TIMESTAMP_V3_UART_OFF_20261114/rebuild_relative.bif\` is only a three-partition layout template. To run it, copy the exact built \`fsbl.elf\`, \`lwip_echo_server.elf\` and the matching \`TIMESTAMP_1US_V3_XU5_TEST.bit\` into the BIF directory. Do not use QEMU PMUFW or substitute a different bitstream. Use Bootgen \`-arch zynqmp\`.

Validated test BOOT.BIN SHA-256:
\`B4AAB46FD459E4A9FB3A96BE7F6241C44B65090F999963F7367645BAF20C28CF\`.

Do **not** overwrite the golden BOOT.BIN. The new Boot is not declared hardware-validated yet.
