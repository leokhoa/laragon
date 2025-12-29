if {[info sharedlibextension] != ".dll"} return
if {[::tcl::pkgconfig get debug]} {
    package ifneeded registry 1.3.5 \
	    [list load [file join $dir tclreg13g.dll] Registry]
} else {
    package ifneeded registry 1.3.5 \
	    [list load [file join $dir tclreg13.dll] Registry]
}
