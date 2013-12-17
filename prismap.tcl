#!/usr/bin/tclsh

package require shapetcl
package require msgcat

::msgcat::mcload [file join [file dirname [info script]] {msgs}]

proc Prismap {arglist} {
	global config
	
	# creates initial config array
	ConfigDefaults
	
	# parses option and updates config
	ConfigOptions $arglist
	
	# reads shapefile and creates shp array
	OpenShapefile $config(in) $config(attr)
	
	# finalize config values that depend on shp data
	ConfigCheck
	
	ConfigLog
	OpenOutput $config(out)
	
	# process each feature in shapefile,
	# generating an OpenSCAD polygon outline from its geometry
	# and extruded according to its attribute value
	Process
	
	CloseOutput
	CloseShapefile
}

proc OpenShapefile {path attr_name} {
	global shp
	
	if {[catch {::shapetcl::shapefile $path} shp(file)]} {
		Abort {Cannot load shapefile: %1$s} $shp(file)
	}
	
	if {[$shp(file) info type] ne "polygon"} {
		Abort {Only polygon shapefiles are supported.}
	}
	
	# count - number of features in shapefile
	set shp(count) [$shp(file) info count]
	if {$shp(count) < 1} {
		Abort {Shapefile contains no features.}
	}

	# attr - index of named attribute
	if {[catch {$shp(file) fields index $attr_name} shp(attr)]} {
		Abort $shp(attr)
	}
	
	# assert that the selected attribute field is numeric 
	set attr_type [lindex [$shp(file) fields list $shp(attr)] 0]
	if {$attr_type ne "integer" && $attr_type ne "double"} {
		Abort {Attribute field type is not numeric (type of "%1$s" is %2$s).} $attr_name $attr_type
	}
	
	# min, max - attribute bounds
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
	
	# xmin, xmax, ymin, ymax - geometry bounding box
	lassign [$shp(file) info bounds] shp(xmin) shp(ymin) shp(xmax) shp(ymax)
	
	# x_offset, y_offset - translation from bounding box center to origin
	set shp(x_offset) [expr {($shp(xmax) + $shp(xmin)) / -2.0}]
	set shp(y_offset) [expr {($shp(ymax) + $shp(ymin)) / -2.0}]
	
	# x_size, y_size - bounding box dimensions
	set shp(x_size) [expr {$shp(xmax) - $shp(xmin)}]
	set shp(y_size) [expr {$shp(ymax) - $shp(ymin)}]
	
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

proc OutputCube {xs ys zs x y z} {
	# x, y, z - position of cube corner
	Output {translate([%f, %f, %f])} $x $y $z
	# xs, ys, zs - cube size
	Output {cube([%f, %f, %f]);} $xs $ys $zs
}

proc ReformatCoords {coords} {
	set points [list]
	set paths [list]
	set index 0
	
	# coords is a list of one or more coordinate lists,
	# each representing part of a single polygon feature
	foreach part $coords {
		set part_path [list]
		
		# each part list consists of a series of x y vertex coordinates.
		# the last vertex repeats the first and can be ignored.
		foreach {x y} [lrange $part 0 end-2] {
			
			# vertices of all parts in the feature are accumulated in a single list...
			lappend points [format {[%s, %s]} $x $y]
			
			# ... but the indices of the vertices that make up each part are grouped...
			lappend part_path $index
			incr index
		}
		
		# ... and each part's path is appended to the feature's path list when complete.
		lappend paths [format {[%s]} [join $part_path ","]]
	}
	
	# return tuple of OpenSCAD polygon() points= and paths= values.
	return [list [join $points ",\n"] [join $paths ",\n"]]
}

proc Floor {} {
	global config
	global shp
	if {$config(floor) != 0} {
		Output {// Floor:}
		# the floor's xy dimensions are the same as the map bounds;
		# floor is positioned under map by translation to bounds min  
		OutputCube \
				$shp(x_size) $shp(y_size) $config(base) \
				$shp(xmin) $shp(ymin) 0
	}
}

proc Walls {} {
	global config
	global shp
	if {$config(walls) != 0} {
		Output {// Walls:}
		# "west" wall (y size extended by wall width to make a clean corner w/north wall)
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
	#   (measure - lower) yields data height in attribute units
	#  ((measure - lower) * scale) yields data height in model units
	# (((measure - lower) * scale) + base) yields total height in model units
	return [expr {$config(base) + ($config(scale) * (double($measure) - $config(lower)))}]
}

proc Process {} {
	global shp
	
	# everything is unioned and relocated to the model origin
	Output "translate(\[%s, %s, 0\]) {\nunion() {" $shp(x_offset) $shp(y_offset)
	
	# floor and wall surfaces will be generated if configured
	Floor
	Walls
	
	for {set i 0} {$i < $shp(count)} {incr i} {
	
		# calculate extrusion height (or skip feature if null)
		set measure [$shp(file) attributes read $i $shp(attr)]
		if {$measure == {}} {
			continue
		}
		set extrusion [ExtrusionHeight $measure]
		
		# get coordinates; may consist of multiple rings
		lassign [ReformatCoords [$shp(file) coordinates read $i]] points paths
		
		# Fortunately, OpenSCAD is able to sort out islands and holes itself,
		# so we don't really need to perform any analysis of the coordinates.
		Output "// Feature: %d, Value: %s, Paths: %d" $i $measure [llength $paths]
		Output "linear_extrude(height=%f)" $extrusion
		Output "polygon(points=\[\n%s\n\], paths=\[\n%s\n\]);" $points $paths
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
					Abort {Base thickness must be numeric.}
				}
				# Arbitrary nonzero minimum base height ensures at least
				# something is printed for features at lower bound of data...
				# and avoids weird results with 0 linear_extrude height.
				if {$config(base) < 0.1} {
					Abort {Base thickness must be >= 0.1 (%2$s).} $config(base)
				}
			}
			-f - --floor {
				set config(floor) 1
			}
			-w - --walls {
				if {[scan [lindex $argl [incr a]] %f config(walls)] != 1} {
					Abort {Wall thickness must be numeric.}
				}
				# Minimum wall thickness set to match minimum base.
				if {$config(walls) < 0.1} {
					Abort {Wall thickness must be >= 0.1 (%2$s).} $config(walls)
				}
				# walls require floor
				set config(floor) 1
			}
			-l - --lower {
				if {[scan [lindex $argl [incr a]] %f config(lower)] != 1} {
					Abort {Lower bound value must be numeric.}
				}
			}
			-u - --upper {
				if {[scan [lindex $argl [incr a]] %f config(upper)] != 1} {
					Abort {Upper bound value must be numeric.}
				}
			}
			-h - --height {
				# height overrides scale even if scale is also specified
				if {[scan [lindex $argl [incr a]] %f config(height)] != 1} {
					Abort {Height must be numeric.}
				}
				if {$config(height) <= 0} {
					Abort {Height must be > 0 (%2$s).} $config(height)
				}
			}
			-s - --scale {
				if {[scan [lindex $argl [incr a]] %f config(scale)] != 1} {
					Abort {Scale must be numeric.}
				}
				if {$config(scale) <= 0} {
					Abort {Scale must be > 0 (%2$s).} $config(scale)
				}
			}
			-i - --in {
				if {$config(in) ne {}} {
					Abort {Input path set multiple times.}
				}
				set config(in) [lindex $argl [incr a]]
			}
			-a - --attribute {
				if {$config(attr) ne {}} {
					Abort {Attribute name set multiple times.}
				}
				set config(attr) [lindex $argl [incr a]]
			}
			-o - --out {
				if {$config(out) ne {}} {
					Abort {Output path set multiple times.}
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
				Abort {Unrecognized option: %1$s} $arg
			}
		}
	}
	
	# check for required arguments
	if {$config(in) == {}} {
		Abort {Shapefile path must be specified with -i or --in.}
	}
	if {$config(attr) == {}} {
		Abort {Attribute name must be specified with -a or --attribute.}
	}
	if {$config(out) == {}} {
		Abort {Output path must be specified with -o or --output.}
	}
}

# Calculates and validates config settings that depend on attribute values
proc ConfigCheck {} {
	global config
	global shp
	
	if {$config(lower) == {}} {
		# default lower bound of extrusion is lower bound of data
		set config(lower) $shp(min)
	} elseif {$config(lower) > $shp(min)} {
		# if lower bound of extrusion is explicitly set, it must not be greater that lower bound of data
		Abort {Lower bound value (%1$s) must be <= minimum attribute value (%2$s).} $config(lower) $shp(min)
	}
	
	if {$config(upper) == {}} {
		# default upper bound of extrusion is upper bound of data
		set config(upper) $shp(max)
	} elseif {$config(upper) < $shp(max)} {
		# if upper bound of extrusion is explicitly set, it must not be lower than upper bound of data
		Abort {Upper bound value (%1$s) must be >= maximum attribute value (%2$s).} $config(upper) $shp(max)
	}
	
	# if height is set, it is used to compute the scale such that extruded height of a
	# value at the upper bound of data would be exactly at the upper bound of extrusion 
	if {$config(height) ne {}} {
		set config(scale) [expr {($config(height) - $config(base)) / ($config(upper) - $config(lower))}]
	} else {
		set config(height) [ExtrusionHeight $config(upper)]
	}
}

proc ConfigLog {} {
	global config
	if {$config(verbose)} {
		# unordered report of config values
		foreach {option value} [array get config] {
			Log "$option: $value"
		}
	}
}

proc PrintUsage {} {
	puts [::msgcat::mc {Usage: %1$s OPTIONS

Prismap generates an OpenSCAD script representing the polygon features of the
input shapefile extruded proportional to the values of a named attribute field.
The intent is to produce tangible 3D printable models of the conceptual data
model beneath choropleth thematic map design - the "prism map".

Preprocessing is advisable to prepare shapefiles for conversion with Prismap.
For printing purposes, all features should comprise a contiguous region. Small
holes or islands should be pruned and complex boundaries shoulds be simplified.

Feature coordinates are retained without modification. If your shapefile's
coordinate system is not suited for Cartesian display, consider working with a
reprojected version instead. (You can rescale OpenSCAD output before printing.)

REQUIRED OPTIONS:

-i/--in PATH
    Read input shapefile from PATH. PATH may identify any basic shapefile part
    (.shp, .shx, or .dbf) or the base name (minus suffix), but all three parts
    must be present. Only xy polygon shapefiles are supported.

-a/--attribute NAME
    Extrude shapefile features according to the value of the attribute field
    NAME. The attribute field type must be numeric (integer or double).

-o/--out PATH
	Write OpenSCAD script to file at PATH. If PATH is a single hyphen character
	("-"), the script is written to standard output.

DATA RANGE OPTIONS:

Use these options to explicitly set fixed bounds for the extrusion. This is
useful to ensure that multiple models (representing a time series, for example)
are output at the same scale and are therefore comparable.

-l/--lower VALUE
	Set the lower bound of the extrusion - the "floor" height. VALUE must be
	less than or equal to the minimum value of the attribute. The default
	VALUE is the minimum value of the attribute.

-u/--upper VALUE
	Set the upper bound of the extrusion - the "ceiling" height. VALUE must be
	greater than or equal to the maximum value of the attribute. The default
	VALUE is the maximum value of the attribute.

SCALING OPTIONS:

-s/--scale FACTOR
	Scaling FACTOR multiplied by attribute values to determine feature height
	in output units. FACTOR must be greater than zero. Default FACTOR is 1.0.

-h/--height VALUE
	Explicitly set the height of the extrusion ceiling (see --upper) in output
	units. VALUE must be greater than zero. Overrides and recalculates --scale.

MODEL OPTIONS:

-b/--base THICKNESS
	Set the THICKNESS in output units of the base layer. A base layer is always
	present. THICKNESS must be greater than or equal to 0.1. Default is 1.0.

-f/--floor
	Expand the base layer to fill the rectangular bounding box of the features.

-w/--walls THICKNESS
	Include walls on two sides of the model, with THICKNESS in output unit. 
	Wall THICKNESS must be greater than or equal to 0.1. Default is 1.0. The
	walls are located adjacent to the -x and +y sides of the bounding box and
	extend to the extrusion ceiling (see --upper).

MISCELLANEOUS OPTIONS:

-v/--verbose
	Print configuration values to standard error.

--help
	Display this usage message.
} [file tail [info script]]]
}

proc Log {msg args} {
	puts stderr [::msgcat::mc $msg {*}$args]
}

proc Abort {msg args} {
	Log $msg {*}$args
	exit 1
}

Prismap $argv
