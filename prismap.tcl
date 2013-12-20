#!/usr/bin/tclsh

package require shapetcl
package require msgcat

::msgcat::mcload [file join [file dirname [info script]] {msgs}]

array set template {

dataOptions
"/* \[Data\] */

// Must be less than or equal to the minimum data value.
lower_bound = %f;

// Must be greater than or equal to the maximum data value.
upper_bound = %f;
%s"

modelOptions
"// preview\[view:south, tilt:top diagonal\]

/* \[Model Options\] */

model_x_max = %f;

model_y_max = %f;

model_z_max = %f;

// Must be less than model Z max. Set to 0 to disable floor. (Floor thickness is automatically set to wall thickness if floor is disabled and walls are enabled.)
floor_thickness = %f; // [0:10]

// Must be less than model X and Y max. Set to 0 to disable walls.
wall_thickness = %f; // [0:10]
"

scriptSetup
"/* \[Hidden\] */

data = \[%s\];
for (dv = data) {
	if (lower_bound > dv) {
		echo(\"Warning: lower bound should be less than or equal to minimum data value.\");
	}
	if (upper_bound < dv) {
		echo(\"Warning: upper bound should be greater than or equal to maximum data value.\");
	}
}

if (floor_thickness >= model_z_max) {
	echo(\"Warning: floor thickness should be less than model Z max.\");
}

if (wall_thickness >= model_x_max || wall_thickness >= model_y_max) {
	echo(\"Warning: wall thickness should be less than model X and Y max.\");
}

x_size = %f;

y_size = %f;

z_scale = (model_z_max - floor_thickness) / (upper_bound - lower_bound);

x_scale = (model_x_max - wall_thickness) / x_size;

y_scale = (model_y_max - wall_thickness) / y_size;

xy_scale = min(x_scale, y_scale);

function extrusionheight(value) = floor_thickness + (z_scale * (value - lower_bound));

Prismap();
"

wallsModule
"module Walls() {
	translate(\[((x_size / -2) * xy_scale) - wall_thickness, (y_size / -2) * xy_scale, 0\])
		cube(\[wall_thickness, (y_size * xy_scale) + wall_thickness, model_z_max\]);
	translate(\[(x_size / -2) * xy_scale, (y_size / 2) * xy_scale, 0\])
		cube(\[x_size * xy_scale, wall_thickness, model_z_max\]);
}
"

floorModule
"module Floor() {
	translate(\[%f, %f, 0\])
		cube(\[x_size, y_size, floor_thickness > 0 ? floor_thickness : wall_thickness\]);
}
"

featureModule
"module feature%d(height) {
	if (height > 0) {
		linear_extrude(height=height) polygon(points=\[
%s
		\], paths=\[
%s
		\]);
	}
}
"

prismapModule
"module Prismap() {
	union() {
		if (wall_thickness > 0) {
			Walls();
		}
		scale(\[xy_scale, xy_scale, 1\]) translate(\[%f, %f, 0\]) {
			if (floor_thickness > 0 || wall_thickness > 0) {
				Floor();
			}
%s		}
	}
}"

}

proc Prismap {} {
	global config
	
	# creates initial config array
	ConfigDefaults
	
	# parses option and updates config
	ConfigOptions $::argv
	
	# reads shapefile and creates shp array
	OpenShapefile
	
	# finalize config values that depend on shp data
	ConfigCheck
	
	ConfigLog
	OpenOutput
	
	# process each feature in shapefile,
	# generating an OpenSCAD polygon outline from its geometry
	# and extruded according to its attribute value
	Process
	
	CloseOutput
	CloseShapefile
}

proc OpenShapefile {} {
	global config
	global shp
	
	if {[catch {::shapetcl::shapefile $config(in)} shp(file)]} {
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
	
	if {$config(attr) == {}} {
		
		# if no attribute field is given, set bounds to default
		set shp(attr) {}
		set shp(min) $config(default)
		set shp(max) $config(default)
		
	} else {
		
		# attr - index of named attribute
		if {[catch {$shp(file) fields index $config(attr)} shp(attr)]} {
			Abort $shp(attr)
		}
	
		# assert that the selected attribute field is numeric 
		set attr_type [lindex [$shp(file) fields list $shp(attr)] 0]
		if {$attr_type ne "integer" && $attr_type ne "double"} {
			Abort {Attribute field type is not numeric (type of "%1$s" is %2$s).} $config(attr) $attr_type
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
	}
	
	if {$config(names) == {}} {
		
		set shp(names) {}
		
	} else {
		
		# names - index of name labels field
		if {[catch {$shp(file) fields index $config(names)} shp(names)]} {
			Abort $shp(names)
		}
		
		# assert that the name field is string
		set name_type [lindex [$shp(file) fields list $shp(names)] 0]
		if {$name_type ne "string"} {
			Abort {Name label field type is not string (type of "%1$s" is %2$s).} $config(names) $name_type
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

proc OpenOutput {} {
	global config
	global out
	if {$config(out) eq "-"} {
		set out stdout
	} elseif {[catch {open $config(out) w} out]} {
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

proc FeatureLabel {id} {
	global shp
	
	if {$shp(names) == {}} {
		return {}
	}
	
	return [format "// %s\n" [$shp(file) attributes read $id $shp(names)]]

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
			lappend points [format "\t\t\t\[%s, %s\]" $x $y]
			
			# ... but the indices of the vertices that make up each part are grouped...
			lappend part_path $index
			incr index
		}
		
		# ... and each part's path is appended to the feature's path list when complete.
		lappend paths [format "\t\t\t\[%s\]" [join $part_path ","]]
	}
	
	# return tuple of OpenSCAD polygon() points= and paths= values.
	return [list [join $points ",\n"] [join $paths ",\n"]]
}

# default feature now considered to be 0?
# don't want to omit features altogether since, since customizers may set values
proc FeatureMeasure {id} {
	global config
	global shp
	if {$config(attr) == {}} {
		# if attribute field is not specified, default value must be
		return $config(default)
	} else {
		set value [$shp(file) attributes read $id $shp(attr)]
		if {$value == {}} {
			# default may be {} as well, but at least we tried.
			return $config(default)
		} else {
			return $value
		}
	}
}

# outputs featureN() modules and main Prismap() module.
proc Process {} {
	global template
	global config
	global shp
	
	for {set i 0} {$i < $shp(count)} {incr i} {
		append dataDefinitions [format "\n%sdata%d = %f;\n" [FeatureLabel $i] $i [FeatureMeasure $i]]
		lappend dataVars [format "data%d" $i]
	}
	
	Output $template(dataOptions) $config(lower) $config(upper) $dataDefinitions
	Output $template(modelOptions) $config(x) $config(y) $config(z) $config(floor) $config(walls)
	Output $template(scriptSetup) [join $dataVars ", "] $shp(x_size) $shp(y_size)
	Output $template(floorModule) $shp(xmin) $shp(ymin)
	Output $template(wallsModule)
	
	for {set i 0} {$i < $shp(count)} {incr i} {
		lassign [ReformatCoords [$shp(file) coordinates read $i]] points paths
		Output $template(featureModule) $i $points $paths
		append featureCommands [format "\t\t\tfeature%d(extrusionheight(data%d));\n" $i $i]
	}
	
	Output $template(prismapModule) $shp(x_offset) $shp(y_offset) $featureCommands
}

proc ConfigDefaults {} {
	global config
	array set config {
		lower   {}
		upper   {}
		
		x   0.0
		y   0.0
		z   0.0
		
		floor   1.0
		walls   1.0
		
		in      {}
		attr    {}
		default 0
		names   {}
		out     {}
		
		verbose 0
	}
}

# Updates config based on command line options
proc ConfigOptions {argl} {
	global config
	for {set a 0} {$a < [llength $argl]} {incr a} {
		set arg [lindex $argl $a]
		switch -- $arg {
			
			-f - --floor {
				if {[scan [lindex $argl [incr a]] %f config(floor)] != 1} {
					Abort {Floor thickness must be numeric.}
				}
				if {$config(floor) < 0} {
					Abort {Floor thickness must be >= 0 (%1$s).} $config(floor)
				}
			}
			-w - --walls {
				if {[scan [lindex $argl [incr a]] %f config(walls)] != 1} {
					Abort {Wall thickness must be numeric.}
				}
				if {$config(walls) < 0} {
					Abort {Wall thickness must be >= 0 (%1$s).} $config(walls)
				}
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
			
			-x {
				if {[scan [lindex $argl [incr a]] %f config(x)] != 1} {
					Abort {X size limit must be numeric.}
				}
				if {$config(x) <= 0} {
					Abort {X size limit must be > 0 (%1$s).} $config(x)
				}
			}
			-y {
				if {[scan [lindex $argl [incr a]] %f config(y)] != 1} {
					Abort {Y size limit must be numeric.}
				}
				if {$config(y) <= 0} {
					Abort {Y size limit must be > 0 (%1$s).} $config(y)
				}
			}
			-z {
				if {[scan [lindex $argl [incr a]] %f config(z)] != 1} {
					Abort {Z size limit must be numeric.}
				}
				if {$config(z) <= 0} {
					Abort {Z size limit must be > 0 (%1$s).} $config(z)
				}
			}
			
			-i - --in {
				if {$config(in) ne {}} {
					Abort {Input path set multiple times.}
				}
				set config(in) [lindex $argl [incr a]]
			}
			-n - --names {
				set config(names) [lindex $argl [incr a]]
			}
			-a - --attribute {
				set config(attr) [lindex $argl [incr a]]
			}
			-d - --default {
				if {[scan [lindex $argl [incr a]] %f config(default)] != 1} {
					Abort {Default attribute value must be numeric.}
				}
			}
			-o - --out {
				if {$config(out) ne {}} {
					Abort {Output path set multiple times.}
				}
				set config(out) [lindex $argl [incr a]]
			}
			--debug {
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
		Abort {Shapefile path must be specified with --in.}
	}
	
	# if we set default default to 0, don't need to require attribute anymore... (todo)
	if {$config(attr) == {} && $config(default) == {}} {
		Abort {Attribute field name or default value must be specified with --attribute or --default, respectively.}
	}
	if {$config(out) == {}} {
		Abort {Output path must be specified with --output.}
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
	
	if {$config(x) == 0} {
		set config(x) $shp(x_size)
	}
	
	if {$config(y) == 0} {
		set config(y) $shp(y_size)
	}
	
	if {$config(z) == 0} {
		# default z height not based on attribute values, but
		# proportioned to x/y dimensions. Best to set explicitly.
		set config(z) [expr {min($config(x), $config(y))}]
	}
}

proc ConfigLog {} {
	global config
	global shp
	if {$config(verbose)} {
		# unordered report of config values
		Log "Config settings:"
		foreach {option value} [array get config] {
			Log "$option: $value"
		}
		Log "Shapefile info:"
		foreach {option value} [array get shp] {
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
-d/--default VALUE
    Extrude shapefile features according to the value of the attribute field
    NAME or, if NAME is not specified, the constant default VALUE. At least one
    of these options must be specified. If both are specified, the default
    value will be used only where there attribute field value is null.
    The attribute field type must be numeric (integer or double).

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

-z VALUE
	Explicitly set the height of the extrusion ceiling (see --upper) in output
	units. VALUE must be greater than zero.

-x VALUE
	Bounding box will be scaled to largest size that fits within VALUE output
	units in the X dimension. If -y is also given, both constraints apply.

-y VALUE
	Bounding box will be scaled to largest size that fits within VALUE output
	units in the Y dimension. If -x is also given, both constraints apply. 

MODEL OPTIONS:

-f/--floor THICKNESS
	Include a floor layer with THICKNESS in output units. The floor layer is
	useful for connecting discontiguous features. The floor is automatically
	enabled if --walls are enabled (wall thickness is used if floor not set).

-w/--walls THICKNESS
	Include walls on two sides of the model, with THICKNESS in output units. 
	Wall THICKNESS must be greater than or equal to 0.1. Default is 1.0. The
	walls are located adjacent to the -x and +y sides of the bounding box and
	extend to the extrusion ceiling (see --upper).

MISCELLANEOUS OPTIONS:

--debug
	Print configuration values and shapefile info to standard error.

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

Prismap
