#!/usr/bin/tclsh

package require shapetcl
package require msgcat

::msgcat::mcload [file join [file dirname [info script]] {msgs}]

# Populates shp() array with shapefile info. shp keys:
# file - shapefile token
# count - entities in shapefile
# xmin, xmax, ymin, ymax - bounding box extents
# x_offset, y_offset - offset to bounding box centroid
# x_size, y_size - bounding box dimensions
# attr - id of extrusion attribute
# min, max - minimum and maximum values of attr
proc OpenShapefile {path attr_name} {
	global shp
	
	if {[catch {::shapetcl::shapefile $path} shp(file)]} {
		Abort [format "Cannot load shapefile: %s" $shp(file)]
	}
	
	set shp(count) [$shp(file) info count]
	if {$shp(count) < 1} {
		Abort "Empty shapefile"
	}
	
	lassign [$shp(file) info bounds] shp(xmin) shp(ymin) shp(xmax) shp(ymax)
	
	# translation to move bounding box to origin
	set shp(x_offset) [expr {($shp(xmax) + $shp(xmin)) / -2.0}]
	set shp(y_offset) [expr {($shp(ymax) + $shp(ymin)) / -2.0}]
	
	# bounding box dimensions
	set shp(x_size) [expr {$shp(xmax) - $shp(xmin)}]
	set shp(y_size) [expr {$shp(ymax) - $shp(ymin)}]
	
	# index of named attribute
	if {[catch {$shp(file) fields index $attr_name} shp(attr)]} {
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

proc CloseShapefile {} {
	global shp
	$shp(file) close
}

proc OpenOutput {path} {
	global out
	if {$path eq "-"} {
		set out stdout
	} elseif {[catch {open $path w} out]} {
		Abort $out
	}
}

proc CloseOutput {} {
	global out
	if {$out ne "stdout"} {
		close $out
	}
}

proc Output {msg args} {
	global out
	puts $out [format $msg {*}$args]
}

# xs ys zs - size
# x y z - location of origin corner
proc OutputCube {xs ys zs x y z} {
	Output "translate(\[%f, %f, %f\])" $x $y $z
	Output "cube(\[%f, %f, %f\]);" $xs $ys $zs
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

proc Floor {} {
	global config
	global shp
	if {$config(floor) != 0} {
		Output "// Floor:"
		OutputCube \
				$shp(x_size) $shp(y_size) $config(base) \
				$shp(xmin) $shp(ymin) 0
	}
}

proc Walls {} {
	global config
	global shp
	if {$config(walls) != 0} {
		Output "// Walls:"
		# "west" wall (extends north to line up with north wall)
		OutputCube \
				$config(walls) [expr {$shp(y_size) + $config(walls)}] $config(height) \
				[expr {$shp(xmin) - $config(walls)}] $shp(ymin) 0
		# "north" wall
		OutputCube \
				$shp(x_size) $config(walls) $config(height) \
				$shp(xmin) $shp(ymax) 0
	}
}

proc ExtrusionHeight {measure} {
	global config
	return [expr {$config(base) + ($config(scale) * (double($measure) - $config(lower)))}]
}

proc Process {} {
	global shp
	
	# combine everything and move it to the origin
	Output "union() {translate(\[%s, %s, 0\]) {" $shp(x_offset) $shp(y_offset)
	
	Floor
	Walls
	
	for {set i 0} {$i < $shp(count)} {incr i} {
	
		# calculate extrusion height
		set measure [$shp(file) attributes read $i $shp(attr)]
		set extrusion [ExtrusionHeight $measure]
		
		# get coordinates; may consist of multiple rings
		lassign [ReformatCoords [$shp(file) coordinates read $i]] points parts
		
		# Fortunately, OpenSCAD seems to be able to sort out islands and holes itself,
		# so all we need to do is reformat the coords lists as a single points list
		# and an associated parts points index list.
		Output "// Feature: %d, Value: %s, Parts: %d" $i $measure [llength $parts]
		Output "linear_extrude(height=%f)" $extrusion
		Output "polygon(points=\[\n%s\n\], paths=\[\n%s\n\]);" $points $parts
	}
	
	# close translate and union
	Output "}}"
}

proc ConfigDefaults {} {
	global config
	array set config {
		base    1.0
		lower   {}
		upper   {}
		height  {}
		scale   1.0
		in      {}
		attr    {}
		out     {}
		floor   0
		walls   0
		verbose 0
	}
}

# Updates config based on command line options
proc ConfigOptions {argl} {
	global config
	for {set a 0} {$a < [llength $argl]} {incr a} {
		set arg [lindex $argl $a]
		switch -- $arg {
			-b - --base {
				if {[scan [lindex $argl [incr a]] %f config(base)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
				if {$config(base) < 0.1} {
					Abort {%1$s must be >= 0.1 (%2$s)} $arg $config(base)
				}
			}
			-f - --floor {
				set config(floor) 1
			}
			-w - --walls {
				if {[scan [lindex $argl [incr a]] %f config(walls)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
				if {$config(walls) < 0.1} {
					Abort {%1$s must be >= 0.1 (%2$s)} $arg $config(walls)
				}
				# walls require floor
				set config(floor) 1
			}
			-l - --lower {
				if {[scan [lindex $argl [incr a]] %f config(lower)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
			}
			-u - --upper {
				if {[scan [lindex $argl [incr a]] %f config(upper)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
			}
			-h - --height {
				if {[scan [lindex $argl [incr a]] %f config(height)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
				if {$config(height) <= 0} {
					Abort {%1$s must be > 0. (%2$s)} $arg $config(height)
				}
			}
			-s - --scale {
				if {[scan [lindex $argl [incr a]] %f config(scale)] != 1} {
					Abort {%1$s must be numeric.} $arg
				}
				if {$config(scale) <= 0} {
					Abort {%1$s must be > 0. (%2$s)} $arg $config(scale)
				}
			}
			-i - --in {
				if {$config(in) ne {}} {
					Abort {--in already set.}
				}
				set config(in) [lindex $argl [incr a]]
			}
			-a - --attribute {
				if {$config(attr) ne {}} {
					Abort {--attribute already set.}
				}
				set config(attr) [lindex $argl [incr a]]
			}
			-o - --out {
				if {$config(out) ne {}} {
					Abort {--out already set.}
				}
				set config(out) [lindex $argl [incr a]]
			}
			-v - --verbose {
				set config(verbose) 1
			}
			--help {
				PrintUsage
				exit 0
			}
			default {
				Abort {unrecognized option %1$s} $arg
			}
		}
	}
	
	# check for required arguments
	if {$config(in) == {}} {
		Abort {--in shapefile must be specified.}
	}
	if {$config(attr) == {}} {
		Abort {-a attribute must be specified.}
	}
	if {$config(out) == {}} {
		Abort {--out scad file must be specified.}
	}
}

# Calculates and validates config settings that depend on attribute values
proc ConfigCheck {} {
	global config
	global shp
	
	if {$config(lower) == {}} {
		set config(lower) $shp(min)
	} elseif {$config(lower) > $shp(min)} {
		Abort {--lower must be <= --attr minimum (%1$s > %2$s)} $config(lower) $shp(min)
	}
	
	if {$config(upper) == {}} {
		set config(upper) $shp(max)
	} elseif {$config(upper) < $shp(max)} {
		Abort {--to must be >= --attr maximum (%1$s < %2$s)} $config(upper) $shp(max)
	}
	
	# if height is set, it is used to compute the scale
	# such that --to would be extruded to height + base.
	if {$config(height) ne {}} {
		set config(scale) [expr {($config(height) - $config(base)) / ($config(upper) - $config(lower))}]
	} else {
		set config(height) [ExtrusionHeight $config(upper)]
	}
}

proc ConfigLog {} {
	global config
	if {$config(verbose)} {
		foreach {option value} [array get config] {
			Log "$option: $value"
		}
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




ConfigDefaults
ConfigOptions $::argv
OpenShapefile $config(in) $config(attr)
ConfigCheck
ConfigLog
OpenOutput $config(out)
Process
CloseOutput
CloseShapefile
