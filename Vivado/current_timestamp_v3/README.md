# Mercury XU5 Timestamp V3 — Vivado 2025.1

**Status: Block Design source files are present, but a fully reproducible bitstream build is NOT verified.**

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
- hpu_aux_paer.xdc in constraints/.
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

The original export also lists files absent from the current V3 snapshot,
including:

- Board constraints: ddr4_pl_fixed_pins.xdc,
  board_fixed_current_ports.xdc, dac8568_pins.xdc,
  bank66_lvcmos18_override.xdc, ad7266_adc_pins.xdc; plus
  spike_programmer_pins.xdc (a distinct earlier copy exists under
  Vivado/constraints, but equivalence was not checked).
- Auxiliary project Tcl: Mercury_XU5_PE1_safe_existing_ports.tcl,
  en_gmii2rgmii_ksz9031_timing.tcl, Mercury_XU5_PE1.tcl,
  Mercury_XU5_timing.tcl, en_gmii2rgmii_loc.tcl, scripts/settings.tcl.
- External/generated logic: en_gmii2rgmii.edn, the original project's
  synth checkpoint DCP, and IIT:IIT_lib:HPU_Core:4.0.
- Simulation sources: tb_axis_spike_programmer.vhd,
  tb_axis_cmd_packet_router.vhd.

Do not copy vendor-licensed EDN, DCP, generated IP or third-party HPU source
into this PUBLIC repository until redistribution rights are verified.
The present V3 Block Design preflight is **not** a claim that constraints,
timing closure, top-level port mapping or the released BOOT.BIN can be
regenerated. A Vivado clean-room run on Windows is still required.

## Error identification

- BD::TCL 103-2021 / "modules not found": module RTL files were not
  registered in sources_1 before sourcing the BD Tcl.
- "AD7266_SPI_SINE_MODEL" in the error list: likely using the **legacy**
  Vivado/Mercury_XU5_export.tcl, not the November V3 BD Tcl.
- "IIT:IIT_lib:HPU_Core:4.0 not found": HPU_Core IP repository needs
  installation/registration, not additional FPGA timestamp RTL.
- Windows path >260 bytes during archive_project: a separate archive
  limitation, not the module-reference error.

**Validation:** repository inventory and generated-script inspection only;
the new rebuild script has not been executed in Vivado by the author of this
fix.
