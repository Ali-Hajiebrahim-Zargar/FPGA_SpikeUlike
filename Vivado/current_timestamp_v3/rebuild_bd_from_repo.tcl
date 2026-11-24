# Mercury XU5 Timestamp V3: fresh Block Design reconstruction from repository RTL.
# Vivado 2025.1 only.
#
# Usage:
#   vivado -mode batch -source rebuild_bd_from_repo.tcl -tclargs <fresh-output-dir> <HPU_Core-ip-repository>
#
# This rebuilds/validates the Block Design only. It does NOT claim to reproduce
# a timing-closed bitstream or the published BOOT.BIN. No original XPR is modified.

if {$argc != 2} {
    error "Usage: -tclargs <fresh-output-dir> <HPU_Core-ip-repository>"
}
set xu5_script_dir [file dirname [file normalize [info script]]]
set xu5_rtl_dir [file join $xu5_script_dir src]
set xu5_bd_script [file join $xu5_script_dir block_designs Mercury_XU5.tcl]
set xu5_output_dir [file normalize [lindex $argv 0]]
set xu5_hpu_repo [file normalize [lindex $argv 1]]
set xu5_project_name XU5_TIMESTAMP_V3_BD_CHECK

if {![string match "2025.1*" [version -short]]} {
    error "Vivado 2025.1 is required; found [version -short]"
}
if {[llength [get_projects -quiet]] != 0} {
    error "A project is already open; run this script in a fresh Vivado batch session."
}
if {![file isdirectory $xu5_rtl_dir]} {
    error "Missing checked-in RTL directory: $xu5_rtl_dir"
}
if {![file isfile $xu5_bd_script]} {
    error "Missing current V3 Block Design Tcl: $xu5_bd_script"
}
if {![file isdirectory $xu5_hpu_repo]} {
    error "HPU Core IP repository not found: $xu5_hpu_repo"
}
if {[file exists $xu5_output_dir]} {
    error "Output path must be new so no previous project is overwritten: $xu5_output_dir"
}

# Explicit entity/file map: the historical name FPGA_TIMESTAMP_TIMER_16
# still denotes a 32-bit, 1-us V3 timestamp counter.
set xu5_module_files {
    {AXIS_CMD_PACKET_ROUTER axis_cmd_packet_router.vhd}
    {AXIS_SPIKE_PROGRAMMER axis_spike_programmer.vhd}
    {FPGA_TIMESTAMP_TIMER_16 fpga_timestamp_timer_16.vhd}
    {AXIS_TELEMETRY_DATA_MANAGER axis_telemetry_data_manager.vhd}
    {AD7266_AXIS_DRIVER ad7266_axis_driver.vhd}
    {axis_dac8568_waveform_driver axis_dac8568_waveform_driver.vhd}
    {AXIS_HPU_CONTROL_BRIDGE axis_hpu_control_bridge.vhd}
    {AXIS_HPU_TELEMETRY_ADAPTER axis_hpu_telemetry_adapter.vhd}
    {AD7266_SPI_SINE_MODEL ad7266_spi_sine_model.vhd}
}

foreach xu5_pair $xu5_module_files {
    lassign $xu5_pair xu5_mod xu5_filename
    if {![file isfile [file join $xu5_rtl_dir $xu5_filename]]} {
        error "Required RTL missing for $xu5_mod: $xu5_filename"
    }
}

set xu5_all_vhd [lsort [glob -nocomplain -directory $xu5_rtl_dir *.vhd]]
if {[llength $xu5_all_vhd] < 16} {
    error "Expected at least 16 VHDL sources in repository; found [llength $xu5_all_vhd]"
}

# Project is only created after all filesystem preflight checks passed.
create_project $xu5_project_name $xu5_output_dir -part xczu5ev-sfvc784-2-i
set_property target_language VHDL [current_project]
set_property enable_vhdl_2008 1 [current_project]

set_property ip_repo_paths [list $xu5_hpu_repo] [get_filesets sources_1]
update_ip_catalog -rebuild
if {[llength [get_ipdefs -all -quiet IIT:IIT_lib:HPU_Core:4.0]] == 0} {
    error "Required custom IP IIT:IIT_lib:HPU_Core:4.0 is absent. Check -tclargs HPU_Core path and IP catalog."
}

# Critical order: add module-reference source files BEFORE the BD Tcl checks
# can_resolve_reference. Do not source the legacy Vivado/Mercury_XU5_export.tcl.
add_files -norecurse -fileset sources_1 $xu5_all_vhd

# Preserve VHDL-2008 file types captured in the original 2025.1 project export.
set xu5_vhdl2008_files {
    axis_dac8568_packet_parser.vhd
    dac8568_waveform_memory.vhd
    dac8568_channel_scheduler.vhd
    dac8568_frame_builder.vhd
    dac8568_init_controller.vhd
    dac8568_spi_master.vhd
}
foreach xu5_name $xu5_vhdl2008_files {
    set xu5_f [get_files -quiet [file join $xu5_rtl_dir $xu5_name]]
    if {[llength $xu5_f] != 1} {
        error "VHDL 2008 source missing from Vivado fileset: $xu5_name"
    }
    set_property file_type {VHDL 2008} $xu5_f
}
update_compile_order -fileset sources_1

set xu5_missing_mods {}
foreach xu5_pair $xu5_module_files {
    set xu5_mod [lindex $xu5_pair 0]
    if {![can_resolve_reference $xu5_mod]} {
        lappend xu5_missing_mods $xu5_mod
    }
}
if {[llength $xu5_missing_mods]} {
    error "MODULE_PREFLIGHT_FAILED: $xu5_missing_mods. Inspect VHDL compile order and entity names."
}
puts "XU5_MODULE_PREFLIGHT_OK: [llength $xu5_module_files] unique entity references resolvable"

# Sourcing generated BD Tcl is now safe with respect to missing module refs.
# Tcl 'return 3' in an exported BD script can be a normal source return value,
# so inspect the resulting actual design, not merely a zero Tcl error status.
source $xu5_bd_script
# The generated script's final Tcl value may be nonempty even on success.
# Check the resulting BD objects and run validation, not that return value.
if {[llength [get_files -quiet Mercury_XU5.bd]] == 0} {
    error "BD creation failed: Mercury_XU5.bd is absent"
}
if {[llength [get_bd_cells -quiet]] == 0} {
    error "BD creation failed: design contains no cells"
}
validate_bd_design
save_bd_design
update_compile_order -fileset sources_1
puts "XU5_BD_REBUILD_OK: [get_property NAME [current_project]]"
puts "XU5_BD_OUTPUT_DIR=$xu5_output_dir"
puts "XU5_NOTE=Block Design validation only; complete original XDC/EDN/HPU dependencies and bitstream rebuild remain separate."
