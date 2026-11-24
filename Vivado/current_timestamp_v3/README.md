# Mercury XU5 Timestamp V3 — Vivado 2025.1

**Status: clean Windows Vivado 2025.1 Block Design and HDL wrapper creation verified on 2026-11-24; full bitstream build is NOT verified.**

The V3 FPGA timer still uses the historical VHDL entity name
FPGA_TIMESTAMP_TIMER_16, despite its 32-bit counter and telemetry V3 header.

## Correct entry point (new Vivado 2025.1 project)

Do NOT source the repository's historical Vivado/Mercury_XU5_export.tcl
to rebuild the current V3 design. That October script expects a different
Block Design, notably AD7266_SPI_SINE_MODEL.

Use a **fresh short output path** and an installed HPU_Core IP repository.
In PowerShell on Windows:

    $vivado = "C:\Xilinx\2025.1\Vivado\bin\vivado.bat"
    $repo = "$env:USERPROFILE\Documents\FPGA_SpikeUlike_stage_20261116"
    & $vivado -mode batch -source "$repo\Vivado\current_timestamp_v3\rebuild_bd_from_repo.tcl" -tclargs "C:\xu5_bd_rebuild_check_20261124" "C:\git\HPU_Core"

Adjust Vivado, repository and HPU_Core paths as needed. The output directory
must not already exist. A successful run prints both XU5_MODULE_PREFLIGHT_OK
and XU5_BD_REBUILD_OK. No synth, implementation, bitstream, or BOOT.BIN
rebuild is performed by this script.

The newly added entry point imports all 16 checked-in VHDL modules into the
Vivado sources_1 fileset, applies the original VHDL-2008 file types,
refreshes the external IP catalog, checks each module reference, and **only
then** sources block_designs/Mercury_XU5.tcl. This fixes the source-order
issue that triggers BD::TCL 103-2021 in an empty project.

## What the GitHub snapshot currently contains

- 16 VHDL files in src/, including all module references in the reported
  BD::TCL error (AD7266_SPI_SINE_MODEL exists but is only required by the
  earlier, non-V3 export).
- Four exported Block Design Tcl files in block_designs/.
- The November original-project export in project_rebuild.tcl.
- Seven original XDC files and one historical board Tcl in constraints/; two original testbenches in sim/ (restored in PR #3).
- Build/source docs, Vitis source and test BOOT.BIN elsewhere in the repo.

## Source control and generated outputs

Rebuild from the checked-in Tcl, VHDL and constraints; do not commit the
generated XPR or its project-specific .srcs, .gen, .runs, .cache, .sim,
.hw, .ip_user_files or .ipdefs trees. The root .gitignore excludes those
containers, intermediate checkpoints, logs, and routine build artifacts.
Choose a fresh short output directory outside the checkout (recommended)
or under build/. Keep canonical RTL, constraints and any essential IP
inputs outside generated project directories before ignoring them.
The exported BD Tcl and intentional release artifacts are exceptions,
not scratch files. The published BOOT.BIN and Qt distribution are retained.
If a necessary IP configuration or vendor netlist is not reproducible,
document its pinned upstream source or preserve a redistributable input
outside the ignored directories; do not silently discard it.

## Remaining gaps for a full portable bitstream rebuild

project_rebuild.tcl is an **unaltered Vivado-generated historical snapshot**.
It references the development machine's C:/xu5/... and C:/git/HPU_Core
directories. It cannot be used as a relocatable standalone project script.

## Candidate portable project preparation

Run on a fresh, short output path. This new entry point is **not yet executed in Vivado**:

    vivado -mode batch -source rebuild_project_from_repo.tcl -tclargs C:/v3p1 C:/FPGA/HPU_Core C:/FPGA/Mercury_XU5_PE1_Reference_Design

The two external repositories must be at the pinned commits documented in the root README.
It reuses the verified BD procedure, checks telemetry/timestamp generics, makes the HDL wrapper,
registers the upstream EDN, active constraints and settings hook, and registers the testbenches.
The original ADC XDC is preserved; only the build copy excludes four stale debug-hub commands.
The original simulation-only board and GMII Tcl are retained as historical/upstream inputs, not
activated for implementation. The generated board_safety.xdc applies the pinned Enclustra
overtemperature shutdown and unused-pin PULLNONE settings explicitly. No guessed pin changes,
incremental DCP, legacy top generic, generated products or bitstream are committed.
Success marker: XU5_PROJECT_PREPARED. This does not launch synthesis or implementation.
Check IP output generation, synthesis, implementation, full port/IOSTANDARD mapping, DRC,
timing, XSA and boot/hardware behaviour before claiming reproducibility or using a new bitstream.

## Error identification

- BD::TCL 103-2021 / "modules not found": module RTL files were not
  registered in sources_1 before sourcing the BD Tcl.
- "AD7266_SPI_SINE_MODEL" in the error list: likely using the **legacy**
  Vivado/Mercury_XU5_export.tcl, not the November V3 BD Tcl.
- "IIT:IIT_lib:HPU_Core:4.0 not found": HPU_Core IP repository needs
  installation/registration, not additional FPGA timestamp RTL.
- Windows path >260 bytes during archive_project: a separate archive
  limitation, not the module-reference error.

**Validation:** the BD-only script and wrapper generation ran successfully on the new laptop in Vivado 2025.1. Reported G_VERSION=0x03, G_HPU_SOURCE_ID=09, G_MAX_PAYLOAD_BYTES=256 and divider=100. The candidate full-project preparation script is still untested.
