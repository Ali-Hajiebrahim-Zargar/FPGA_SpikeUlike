
# Safe wrapper for Mercury_XU5_PE1.tcl
# Applies valid constraints and skips invalid/missing-port constraints.

rename set_property __ORIGINAL_SET_PROPERTY

proc set_property {args} {
    if {[llength $args] >= 3} {
        set OBJECTS [lindex $args end]

        if {[llength $OBJECTS] == 0} {
            return ""
        }
    }

    if {[catch {uplevel 1 [list __ORIGINAL_SET_PROPERTY {*}$args]} RESULT]} {
        puts "SAFE_SKIP_SET_PROPERTY: $RESULT"
        return ""
    }

    return $RESULT
}

source "C:/xu5/Mercury_XU5_PE1_Reference_Design/src/Mercury_XU5_PE1.tcl"

rename set_property {}
rename __ORIGINAL_SET_PROPERTY set_property

