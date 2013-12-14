#!/usr/bin/tclsh

package provide prismap 1.0
package require shapetcl

package require msgcat
::msgcat::mcload [file join [file dirname [info script]] {msgs}]

# Populates shp() array with shapefile info. shp keys:
# file - shapefile token
# count - entities in shapefile
# x_offset, y_offset - offset to bounding box centroid
# x_size, y_size - bounding box dimensions
# attr - id of extrusion attribute
# min, max - minimum and maximum values of attr
proc LoadShapefile {} {
	global config
	global shp
	
	set shp(file) [::shapetcl::shapefile $config(shp)]
	
	set shp(count) [$shp(file) info count]
	if {$shp(count) < 1} {
		Abort "Empty shapefile"
	}
	
	lassign [$shp(file) info bounds] xmin ymin xmax ymax
	
	# translation to move bounding box to origin
	set shp(x_offset) [expr {($xmax + $xmin) / -2.0}]
	set shp(y_offset) [expr {($ymax + $ymin) / -2.0}]
	
	# bounding box dimensions
	set shp(x_size) [expr {$xmax - $xmin}]
	set shp(y_size) [expr {$ymax - $ymin}]
	
	# index of named attribute
	if {[catch {$shp(file) fields index $config(attr)} shp(attr)]} {
		Abort $shp(attr)
	}
	
	# get attribute min/max values (initialize to first)
	set shp(min) [set shp(max) [$shp(file) attribute read 0 $shp(attr)]]
	for {set i 1} {$i < $shp(count)} {incr i} {
		set value [$shp(file) attribute read $i $shp(attr)]
		if {$value < $shp(min)} {
			set shp(min) $value
		}
		if {$value > $shp(max)} {
			set shp(max) $value
		}
	}
}

proc Output {line} {
	global config
	puts $config(out) $line
}

# return a tuple of point list and part point index list
proc ReformatCoords {coords} {
	set points [list]
	set parts [list]
	set index 0
	foreach part $coords {
		set part_points [list]		
		foreach {x y} [lrange $part 0 end-2] {
			lappend points [format "\[%s, %s\]" $x $y]
			lappend part_points $index
			incr index
		}
		lappend parts [format "\[%s\]" [join $part_points ","]]
	}
	return [list [join $points ",\n"] [join $parts ",\n"]]
}

proc BaseBox {} {
	global config
	global shp
	if {$config(box)} {
		Output [format "// Base box:"]
		Output [format "translate(\[%f, %f, 0\])" [expr {$shp(x_size) / -2.0}] [expr {$shp(y_size) / -2.0}]]
		Output [format "cube(size=\[%s, %s, %s\]);"  $shp(x_size) $shp(y_size) $config(base)]
	}
}

proc ExtrusionHeight {measure} {
	global config
	return [expr {$config(base) + (double($config(scale)) * ($measure - $config(floor)))}]
}

proc Process {} {
	global shp
	
	Output "union() {"
	
	BaseBox
	
	Output [format "translate(\[%s, %s, 0\]) {" $shp(x_offset) $shp(y_offset)]
		
	for {set i 0} {$i < $shp(count)} {incr i} {
	
		# calculate extrusion height
		set measure [$shp(file) attributes read $i $shp(attr)]
		set extrusion [ExtrusionHeight $measure]
		
		# get coordinates; may consist of multiple rings
		lassign [ReformatCoords [$shp(file) coordinates read $i]] points parts
		
		# Fortunately, OpenSCAD seems to be able to sort out islands and holes itself,
		# so all we need to do is reformat the coords lists as a single points list
		# and an associated parts points index list.
		Output [format "// Feature: %d, Value: %s, Parts: %d" $i $measure [llength $parts]]
		Output [format "linear_extrude(height=%f) " $extrusion]
		Output [format "polygon(points=\[\n%s\n\], paths=\[\n%s\n\]);" $points $parts]
	}
	
	# close translate and union
	Output "}\n}"
}

# Initializes config settings
proc ConfigInitialDefaults {} {
	global config
	array set config {
		base   1.0
		floor  {}
		ceil   {}
		height {}
		scale  1.0
		shp    {}
		attr   {}
		out    stdout
		box    0
	}
}

# Updates config settings based on command line options
proc ConfigOptions {argl} {
	global config
	for {set a 0} {$a < [llength $argl]} {incr a} {
		set arg [lindex $argl $a]
		switch -- $arg {
			
			--base {
				if {[scan [lindex $argl [incr a]] %f config(base)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
				if {$config(base) < 0.1} {
					Abort {%1$s must be >= 0.1 (%2$s)} $arg $config(base)
				}
			}
			--box {
				set config(box) 1
			}
			
			
			--floor {
				if {[scan [lindex $argl [incr a]] %f config(floor)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
			}
			--ceil {
				if {[scan [lindex $argl [incr a]] %f config(ceil)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
			}
			
			--height {
				if {[scan [lindex $argl [incr a]] %f config(height)] != 1} {
					Abort {$%1$s must be numeric.} $arg
				}
				if {$config(height) <= 0} {
					Abort {%1$s must be > 0. (%2$s)} $arg $config(height)
				}
			}
			--scale {
				if {[scan [lindex $argl [incr a]] %f config(scale)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
				if {$config(scale) == 0} {
					Abort {%1$s must not be 0.} $arg
				}
			}
			
			-i -
			--in {
				if {$config(shp) ne {}} {
					Abort {--in already set.}
				}
				set config(shp) [lindex $argl [incr a]]
			}
			-a -
			--attribute {
				if {$config(attr) ne {}} {
					Abort {--attribute already set.}
				}
				set config(attr) [lindex $argl [incr a]]
			}
			
			-o -
			--out {
				
				if {$config(out) ne "stdout"} {
					Abort {--out already set.}
				}
				
				set ofile [lindex $argl [incr a]]
				
				# - explicitly sets output to stdout, the default
				if {$ofile eq "-"} {
					continue
				}
				
				if {[catch {open $ofile w} config(out)]} {
					Abort $config(out)
				}
			}
			
			-h -
			--help {
				PrintUsage
				exit 0
			}
			default {
				Abort {unrecognized option $arg}
			}
		}
	}
	
	# check for required arguments: shapefile and extrusion attribute
	if {$config(shp) == {}} {
		Abort {--in shapefile must be specified.}
	}
	if {$config(attr) == {}} {
		Abort {-a attribute must be specified.}
	}
}

# Updates config settings based on input attribute values.
proc ConfigDynamicDefaults {} {
	global config
	global shp
	
	if {$config(floor) == {}} {
		set config(floor) $shp(min)
	} elseif {$config(floor) > $shp(min)} {
		Abort {--floor must be <= --attr minimum (%1$s > %2$s)} $config(floor) $shp(min)
	}
	
	if {$config(ceil) == {}} {
		set config(ceil) $shp(max)
	} elseif {$config(ceil) < $shp(max)} {
		Abort {--ceil must be >= --attr maximum (%1$s < %2$s)} $config(ceil) $shp(max)
	}
	
	# if height is set, it is used to compute the scale
	# such that ceil would be extruded to height + base.
	if {$config(height) ne {}} {
		set config(scale) [expr {double($config(height)) / double($config(ceil))}]
	}
}

proc Cleanup {} {
	global config
	global shp
	
	$shp(file) close
	
	if {$config(out) ne "stdout"} {
		close $config(out)
	}
}

proc PrintUsage {} {
	puts [::msgcat::mc {Usage: prismap [OPTIONS]}]
	# placeholder
}

proc Log {msg args} {
	puts stderr [::msgcat::mc $msg {*}$args]
}

proc Abort {msg args} {
	Log $msg {*}$args
	exit 1
}




ConfigInitialDefaults
ConfigOptions $::argv
LoadShapefile
ConfigDynamicDefaults
Process
Cleanup
