# Export real Mercury XU5 Vivado 2025.1 project (source-only).
# vivado.bat -mode batch -source export_current_project.tcl -tclargs <project.xpr> <output-dir>
if {$argc != 2} { error "Expected <project.xpr> <output-dir>" }
set project_xpr [file normalize [lindex $argv 0]]
set out_dir [file normalize [lindex $argv 1]]
if {![file exists $project_xpr]} { error "Project not found: $project_xpr" }
file mkdir $out_dir
set bd_dir [file join $out_dir block_designs]
file mkdir $bd_dir
open_project $project_xpr
puts "XU5_VIVADO_PROJECT=[get_property NAME [current_project]]"
puts "XU5_PART=[get_property PART [current_project]]"
write_project_tcl -force -all_properties [file join $out_dir project_rebuild.tcl]
set bd_files [get_files -quiet -all -filter {FILE_TYPE == "Block Designs"}]
puts "XU5_BLOCK_DESIGNS_COUNT=[llength $bd_files]"
foreach bd_file $bd_files {
    open_bd_design $bd_file
    set bd_name [file rootname [file tail $bd_file]]
    set bd_tcl [file join $bd_dir [format "%s.tcl" $bd_name]]
    write_bd_tcl -force $bd_tcl
    puts "XU5_EXPORTED_BD=$bd_tcl"
}
set zip_path [file join $out_dir vivado_source_archive.zip]
archive_project -force -exclude_run_results $zip_path
puts "XU5_PROJECT_TCL=[file join $out_dir project_rebuild.tcl]"
puts "XU5_SOURCE_ARCHIVE=$zip_path"
close_project
