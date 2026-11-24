# Prepare a fresh V3 project (no synthesis, implementation or bitstream).
# Vivado 2025.1: -tclargs <new-output-dir> <HPU_Core> <Enclustra-reference>
# Historical source files are never edited. Derived files are kept in the build directory.
if {$argc != 3} {
    error "Usage: -tclargs <new-output-dir> <HPU_Core> <Enclustra-reference>"
}
set full_root [file dirname [file normalize [info script]]]
set full_out [file normalize [lindex $argv 0]]
set full_hpu [file normalize [lindex $argv 1]]
set full_en [file normalize [lindex $argv 2]]
set full_constr [file join $full_root constraints]
set full_required {
    spike_programmer_pins.xdc
    ddr4_pl_fixed_pins.xdc
    board_fixed_current_ports.xdc
    dac8568_pins.xdc
    bank66_lvcmos18_override.xdc
    hpu_aux_paer.xdc
    ad7266_adc_pins.xdc
}
foreach name $full_required {
    if {![file isfile [file join $full_constr $name]]} {error "Missing constraint: $name"}
}
foreach name {src/en_gmii2rgmii.edn src/Mercury_XU5_timing.tcl scripts/settings.tcl} {
    if {![file isfile [file join $full_en $name]]} {error "Missing upstream input: $name"}
}
foreach name {tb_axis_cmd_packet_router.vhd tb_axis_spike_programmer.vhd} {
    if {![file isfile [file join $full_root sim $name]]} {error "Missing testbench: $name"}
}

# Reuse the clean-machine-tested module registration and BD entry point.
set full_original_argv $argv
set full_original_argc $argc
set argv [list $full_out $full_hpu]
set argc 2
source [file join $full_root rebuild_bd_from_repo.tcl]
set argv $full_original_argv
set argc $full_original_argc

set full_bd [get_files -quiet Mercury_XU5.bd]
if {[llength $full_bd] != 1} {error "Expected exactly one Mercury_XU5.bd"}
set_property synth_checkpoint_mode Hierarchical $full_bd
set full_tm [get_bd_cells axis_telemetry_data_manager_0]
set full_timer [get_bd_cells fpga_timestamp_timer_16_0]
foreach {obj prop wanted} [list $full_tm G_VERSION 0x03 $full_tm G_HPU_SOURCE_ID 09 $full_tm G_MAX_PAYLOAD_BYTES 256 $full_timer G_TICK_DIVIDER 100] {
    set actual [get_property CONFIG.$prop $obj]
    if {$actual ne $wanted} {error "Unexpected $prop: $actual (expected $wanted)"}
    puts "XU5_GENERIC_OK: $prop=$actual"
}
set full_wrapper [make_wrapper -files $full_bd -top]
if {[llength $full_wrapper] != 1 || ![file isfile [lindex $full_wrapper 0]]} {
    error "Wrapper generation failed"
}
add_files -norecurse -fileset sources_1 $full_wrapper
set_property top Mercury_XU5_wrapper [get_filesets sources_1]
set_property top_auto_set 0 [get_filesets sources_1]
# The generated wrapper already has one BG bit; it declares no BG_WIDTH generic.
# Do not transfer the historical stale top generic BG_WIDTH=1.
set full_edn [file join $full_en src en_gmii2rgmii.edn]
add_files -norecurse -fileset sources_1 $full_edn

set full_derived [file join $full_out local_inputs]
file mkdir $full_derived
# Original ADC source contains four stale debug-hub commands. Remove exactly
# those from the build copy only, leaving all physical pin lines unchanged.
set f [open [file join $full_constr ad7266_adc_pins.xdc] r]
set adc_original [read $f]
close $f
set f [open [file join $full_derived ad7266_adc_pins.xdc] w]
set removed 0
foreach line [split $adc_original "\n"] {
    if {[regexp {^\s*(set_property\s+C_(CLK_INPUT_FREQ_HZ|ENABLE_CLK_DIVIDER|USER_SCAN_CHAIN)\s+.*\[get_debug_cores dbg_hub\]|connect_debug_port\s+dbg_hub/clk\s+\[get_nets clk\])\s*$} $line]} {
        incr removed
        continue
    }
    puts $f $line
}
close $f
if {$removed != 4} {error "ADC debug-command count changed: $removed"}
puts "XU5_ADC_DEBUG_COMMANDS_EXCLUDED=$removed"

proc xu5_add_constraint {path type order stages} {
    add_files -norecurse -fileset constrs_1 $path
    set obj [get_files -of_objects [get_filesets constrs_1] [list $path]]
    if {[llength $obj] != 1} {error "Cannot register constraint: $path"}
    set_property file_type $type $obj
    set_property processing_order $order $obj
    set_property used_in $stages $obj
    puts "XU5_CONSTRAINT: [file tail $path] $order $stages"
}
# Match the active synthesis/implementation constraint roles in the original
# project export. Legacy simulation-only board/GMII Tcl is not activated.
xu5_add_constraint [file join $full_en src Mercury_XU5_timing.tcl] TCL NORMAL {implementation simulation}
foreach name {spike_programmer_pins.xdc ddr4_pl_fixed_pins.xdc board_fixed_current_ports.xdc} {
    xu5_add_constraint [file join $full_constr $name] XDC NORMAL {implementation}
}
xu5_add_constraint [file join $full_constr dac8568_pins.xdc] XDC NORMAL {synthesis implementation}
xu5_add_constraint [file join $full_constr bank66_lvcmos18_override.xdc] XDC LATE {implementation}
xu5_add_constraint [file join $full_constr hpu_aux_paer.xdc] XDC LATE {synthesis implementation}
xu5_add_constraint [file join $full_derived ad7266_adc_pins.xdc] XDC NORMAL {synthesis implementation}

# Explicit safety settings from the pinned Enclustra PE1 board Tcl, without
# applying its incompatible legacy top-level pin names or swallowing errors.
# This is a deliberate safety addition, not proof of bitstream equivalence.
set full_safety [file join $full_derived board_safety.xdc]
set f [open $full_safety w]
puts $f {set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]}
puts $f {set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]}
close $f
xu5_add_constraint $full_safety XDC LATE {implementation}

# Original pre-run hook is retained via a generated adapter selecting the
# actual module, instead of the upstream default 2CG module or batch argv.
set full_hook [file join $full_derived settings_hook.tcl]
set f [open $full_hook w]
puts $f {set module_name ME-XU5-5EV-2I-D12E}
puts $f {set baseboard PE1}
puts $f {set xu5_saved_argv $argv}
puts $f {set argv {}}
puts $f [list source [file join $full_en scripts settings.tcl]]
puts $f {set argv $xu5_saved_argv}
close $f
set_property STEPS.SYNTH_DESIGN.TCL.PRE $full_hook [get_runs synth_1]
set_property STEPS.INIT_DESIGN.TCL.PRE $full_hook [get_runs impl_1]
set_property auto_incremental_checkpoint 0 [get_runs synth_1]
set_property auto_incremental_checkpoint 0 [get_runs impl_1]

foreach name {tb_axis_cmd_packet_router.vhd tb_axis_spike_programmer.vhd} {
    add_files -norecurse -fileset sim_1 [file join $full_root sim $name]
}
set_property top tb_axis_cmd_packet_router [get_filesets sim_1]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
save_bd_design
puts "XU5_PROJECT_PREPARED: [get_property NAME [current_project]]"
puts "XU5_TOP=[get_property top [get_filesets sources_1]]"
puts "XU5_OUTPUT=$full_out"
puts "XU5_NOTE=Preparation only; output products, synthesis, implementation, DRC and timing still require validation."
close_project
