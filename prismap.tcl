#!/usr/bin/tclsh

package require shapetcl
package require msgcat

# (TODO: should be optional, with reprojection enabled only if mapproj available)
package require mapproj

::msgcat::mcload [file join [file dirname [info script]] {msgs}]

array set projections {
	toPlateCarree                 {%f %f}
	toCylindricalEqualArea        {%f %f}
	toMercator                    {%f %f}
	toMillerCylindrical           {%f}
	toSinusoidal                  {%f %f}
	toMollweide                   {%f}
	toEckertIV                    {%f}
	toEckertVI                    {%f}
	toRobinson                    {%f}
	toCassini                     {%f %f}
	toPeirceQuincuncial           {%f}
	toOrthographic                {%f %f}
	toStereographic               {%f %f}
	toGnomonic                    {%f %f}
	toAzimuthalEquidistant        {%f %f}
	toLambertAzimuthalEqualArea   {%f %f}
	toHammer                      {%f}
	toConicEquidistant            {%f %f %f %f}
	toAlbersEqualAreaConic        {%f %f %f %f}
	toLambertConformalConic       {%f %f %f %f}
	toLambertCylindricalEqualArea {%f %f}
	toBehrmann                    {%f %f}
	toTrystanEdwards              {%f %f}
	toHoboDyer                    {%f %f}
	toGallPeters                  {%f %f}
	toBalthasart                  {%f %f}
}

array set template {

header
"// Generated with Prismap, written by Jim DeVona
// https://github.com/anoved/prismap
"

dataOptions
"/* \[Data\] */

// Should be less than or equal to the minimum data value.
lower_bound = %g;

// Should be greater than or equal to the maximum data value.
upper_bound = %g;
%s"

modelOptions
"// preview\[view:south, tilt:top diagonal\]

/* \[Model Options\] */

// Maximum x size in output units (typically mm).
x_size_limit = %g;

// Maximum y size in output units (typically mm).
y_size_limit = %g;

// Maximum z size in output units (typically mm).
z_size_limit = %g;

// Must be less than z size limit.
base_thickness = %g; // \[0:10\]

// Must be less than z size limit. Set to 0 to disable floor.
floor_thickness = %g; // \[0:10\]

walls_enabled = %g; // \[0:No, 1:Yes\]

// Scaling factor applied to all features. This is a fudge factor to facilitate STL export; it forces shared edges to overlap rather than coincide.
inflation = %g;
"

scriptSetup
"/* \[Hidden\] */

extent = \[%g, %g\];

z_scale = (z_size_limit - base_thickness) / (upper_bound - lower_bound);

x_scale = x_size_limit / extent\[0\];

y_scale = y_size_limit / extent\[1\];

xy_scale = min(x_scale, y_scale);

function extrusionheight(value) = base_thickness + (z_scale * (value - lower_bound));

Prismap();
"

wallsModule
"module Walls() {
	linear_extrude(height = floor_thickness + z_size_limit)
	polygon(points=%s);
}
"

floorModule
"module Floor() {
	linear_extrude(height = floor_thickness)	
	polygon(points=%s);
}
"

inflateModule
"// Scale children modules around point
module Inflate(x, y) {
	if (inflation == 1) {
		child();
	}
	else {
		translate(\[x, y, 0\]) scale(\[inflation, inflation, 1\]) translate(\[-x, -y, 0\]) child();
	}
}
"

extrudeModule
"module Extrude(height) {
	if (height > 0) {
		translate([0, 0, floor_thickness]) linear_extrude(height=height) child();
	}
}
"

featureModule
"module feature%d() {
	polygon(points=\[
%s
		\], paths=\[
%s
	\]);
}
"

prismapModule
"module Prismap() {
	union() {
		scale(\[xy_scale, xy_scale, 1\]) translate(\[%g, %g, 0\]) {
			if (floor_thickness > 0) {
				Floor();
			}
			if (walls_enabled != 0) {
				Walls();
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
	
	# xming, xmaxg, yming, ymaxg - geometry bounding box (unprojected)
	lassign [$shp(file) info bounds] shp(xming) shp(yming) shp(xmaxg) shp(ymaxg)
	
	lassign [Reproject $shp(xming) $shp(yming)] shp(xmin) shp(ymin)
	lassign [Reproject $shp(xmaxg) $shp(ymaxg)] shp(xmax) shp(ymax)
	
	# x_offset, y_offset - translation from bounding box center to origin
	set shp(x_offset) [expr {($shp(xmax) + $shp(xmin)) / -2.0}]
	set shp(y_offset) [expr {($shp(ymax) + $shp(ymin)) / -2.0}]
	
	# x_extent, y_extent - bounding box dimensions
	set shp(x_extent) [expr {$shp(xmax) - $shp(xmin)}]
	set shp(y_extent) [expr {$shp(ymax) - $shp(ymin)}]
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

# Returns empty string if there is no label for feature id,
# otherwise returns comment line containing feature name
proc FeatureLabel {id} {
	global shp
	if {$shp(names) == {}} {
		return {}
	}
	return [format "// %s\n" [$shp(file) attributes read $id $shp(names)]]
}

# Returns default attribute measure if no attribute field defined
# or if the attribute measure for feature id is null, otherwise
# returns attribute measure for feature id.
proc FeatureMeasure {id} {
	global config
	global shp
	if {$config(attr) == {}} {
		return $config(default)
	} else {
		set value [$shp(file) attributes read $id $shp(attr)]
		if {$value == {}} {
			return $config(default)
		} else {
			return $value
		}
	}
}

# projspec is the string recieved from the command line describing the projection
proc SetProjection {projspec} {
	
	global projections
	
	# projections is an array like:
	# array set projections {toAlbersEqualAreaConic {%f %f %f %f}}
	
	set name [lindex $projspec 0]
	set params [lrange $projspec 1 end]
	
	if {![info exists projections($name)]} {
		error [format "Unrecognized projection: %s" $name]
	}
	
	if {[llength $params] != [llength $projections($name)]} {
		error [format "Expected %d projection parameters." [llength $projections($name)]]
	}
	
	# asserts that projection parameters are numeric,
	# but does not guard against projection-specific domain errors
	# (eg, valid parameter values may be constrained to a certain range)
	foreach param $params {
		if {![string is double $param]} {
			error [format "Projection parameters should be numeric (%s is not)" $param]
		}
	}
	
	return [format "::mapproj::$name $projections($name)" {*}$params]
}

proc FeatureGeometry {i} {
	global shp
	
	set points [list]
	set paths [list]
	set index 0
	
	# geometry consists of one or more coordinate lists,
	# each representing part of a single polygon feature
	foreach part [$shp(file) coordinates read $i] {
		set part_path [list]
		
		# each part list consists of a series of x y vertex coordinates.
		# the last vertex repeats the first and can be ignored.
		foreach {x y} [lrange $part 0 end-2] {
			
			lassign [Reproject $x $y] x y
			
			# vertices of all parts in the feature are accumulated in a single list...
			lappend points [format "\t\t\[%s, %s\]" $x $y]
			
			# ... but the indices of the vertices that make up each part are grouped...
			lappend part_path $index
			incr index
		}
		
		# ... and each part's path is appended to the feature's path list when complete.
		lappend paths [format "\t\t\[%s\]" [join $part_path ","]]
	}
	
	# return tuple of OpenSCAD polygon() points= and paths= values.
	return [list [join $points ",\n"] [join $paths ",\n"]]
}

# return centroid (bounding box center) of feature i as xy tuple
proc FeatureCentroid {i} {
	global shp
	lassign [$shp(file) info bounds $i] xmin ymin xmax ymax
	set cx [expr {($xmin + $xmax) / 2.0}]
	set cy [expr {($ymin + $ymax) / 2.0}]
	lassign [Reproject $cx $cy] cx cy
	return [list $cx $cy]
}

proc wall_offset {} {
	global config
	global shp
	# compute x/y extents from maxg-ming instead of using cached _extents,
	# which are based on projected min/max. We want original extent.
	# it would be tidier to compute and cache this where shp is set up.
	set y_scale [expr {($config(y) - $config(walls)) / ($shp(ymaxg) - $shp(yming))}]
	set x_scale [expr {($config(x) - $config(walls)) / ($shp(xmaxg) - $shp(xming))}]
	set xy_scale [expr {min($x_scale, $y_scale)}]
	return [expr {$config(walls) / double($xy_scale)}]
}

proc Floorpan {} {
	global shp
	
	set segments 10
	
	set x_interval [expr {($shp(xmaxg) - $shp(xming)) / double($segments)}]
	set y_interval [expr {($shp(ymaxg) - $shp(yming)) / double($segments)}]
	set wall_offset [wall_offset]
	
	for {set i 0} {$i <= $segments} {incr i} {
		
		# 0 to 1
		lassign [Reproject [expr {$shp(xming) + ($i * $x_interval)}] $shp(ymaxg)] x y
		lappend p1 "\[$x, $y\]"
		
		# 1 to 0, a bit past ymax (for wall thickness)
		lassign [Reproject [expr {$shp(xmaxg) - ($i * $x_interval)}] [expr {$shp(ymaxg) + $wall_offset}]] x y
		lappend p1wall "\[$x, $y\]"
		
		# 1 to 2
		lassign [Reproject $shp(xmaxg) [expr {$shp(ymaxg) - ($i * $y_interval)}]] x y
		lappend p2 "\[$x, $y\]"
		
		# 2 to 3
		lassign [Reproject [expr {$shp(xmaxg) - ($i * $x_interval)}] $shp(yming)] x y
		lappend p3 "\[$x, $y\]"
		
		# 3 to 0
		lassign [Reproject $shp(xming) [expr {$shp(yming) + ($i * $y_interval)}]] x y
		lappend p4 "\[$x, $y\]"
		
		# 0 to 3, a bit below xmin (for wall thickness)
		lassign [Reproject [expr {$shp(xming) - $wall_offset}] [expr {$shp(ymaxg) - ($i * $y_interval)}]] x y
		lappend p4wall "\[$x, $y\]"
	}
	
	set floor_points [format {[%s, %s, %s, %s]} [join $p1 {,}] [join $p2 {,}] [join $p3 {,}] [join $p4 {,}]]
	
	# compute corner point for walls
	lassign [Reproject [expr {$shp(xming) - $wall_offset}] [expr {$shp(ymaxg) + $wall_offset}]] x y
	
	set walls_points [format {[%s, %s, %s, %s, %s]} [join $p4 {,}] [join $p1 {,}] [join $p1wall {,}] [format {[%s, %s]} $x $y] [join $p4wall {,}]]
	
	return [list $floor_points $walls_points]
}


proc Process {} {
	global template
	global config
	global shp
	
	for {set i 0} {$i < $shp(count)} {incr i} {
		lappend indices $i
		lappend labels [FeatureLabel $i]
	}
	
	# shpindices lists the shapefile feature indices in output order
	if {$config(sort)} {
		set shpindices [lsort -dictionary -indices $labels]
	} else {
		set shpindices $indices
	}
	
	foreach i $shpindices fid $indices {
		append dataDefinitions [format "\n%sdata%d = %s;\n" [lindex $labels $i] $fid [FeatureMeasure $i]]
	}
	
	Output $template(header)
	Output $template(dataOptions) $config(lower) $config(upper) $dataDefinitions
	
	# in this layer, config(floor) represents floor thickness, but we pass it to the OpenSCAD script
	# as a boolean - just whether or not the floor has nonzero thickness
	Output $template(modelOptions) $config(x) $config(y) $config(z) $config(base) [expr {$config(floor) > 0}] $config(walls) $config(inflation)
	Output $template(scriptSetup) $shp(x_extent) $shp(y_extent)
	
	lassign [Floorpan] floor_points walls_points
	Output $template(floorModule) $floor_points
	Output $template(wallsModule) $walls_points
	
	Output $template(inflateModule)
	Output $template(extrudeModule)
	
	foreach i $shpindices fid $indices {
		
		lassign [FeatureGeometry $i] points paths
		lassign [FeatureCentroid $i] cx cy
		
		Output $template(featureModule) $fid $points $paths
		append featureCommands [format "\t\t\tInflate(%s, %s) Extrude(extrusionheight(data%d)) feature%d();\n" $cx $cy $fid $fid]
	}
	
	Output $template(prismapModule) $shp(x_offset) $shp(y_offset) $featureCommands
}

proc ConfigDefaults {} {
	global config
	array set config {
		lower   {}
		upper   {}
		
		x       0.0
		y       0.0
		z       0.0
		inflation 1
		projname {}
		
		base    0.0
		floor   0.0
		walls   0.0
		
		in      {}
		attr    {}
		default 0
		names   {}
		out     {}
		sort    0
		
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
				if {$config(base) < 0} {
					Abort {Base thickness must be >= 0 (%1$s).} $config(base)
				}
			}
			
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
			
			--projection {
				set config(projname) [lindex $argl [incr a]]
			}
			
			--inflation {
				if {[scan [lindex $argl [incr a]] %f config(inflation)] != 1} {
					Abort {Inflation factor must be numeric.}
				}
				if {$config(inflation) < 1} {
					Abort {Inflation factor must be >= 1 (%1$s).} $config(inflation)
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
			--sort {
				set config(sort) 1
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
	
	if {$config(projname) != {}} {
		
		if {[catch {SetProjection $config(projname)} projproc]} {
			Abort $projproc
		}
		
		# if a projection is defined, Reproject transforms lon/lat to get x y
		proc Reproject {lambda phi} [format {
			lassign [%s $lambda $phi] x y
			return [list [expr {$x * 1000.0}] [expr {$y * 1000.0}]]
		} $projproc]
		
	} else {
		
		# if no projection is given, Reproject simply returns lon/lat as x y
		proc Reproject {lambda phi} {
			return [list $lambda $phi]
		}
		
	}
	
	# check for required arguments
	if {$config(in) == {}} {
		Abort {Shapefile path must be specified with --in.}
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
	}
	
	if {$config(upper) == {}} {
		# default upper bound of extrusion is upper bound of data
		set config(upper) $shp(max)
	}
	
	if {$config(x) == 0} {
		set config(x) $shp(x_extent)
	}
	
	if {$config(y) == 0} {
		set config(y) $shp(y_extent)
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
The OpenSCAD output is compatible with Makerbot Thingiverse Customizer.

Preprocessing is advisable to prepare shapefiles for conversion with Prismap.
Small holes or islands should be pruned and complex boundaries shoulds be
simplified. Feature coordinates are retained without modification. If your
shapefile's coordinate system is not suited for Cartesian display, consider
working with a reprojected version instead.

REQUIRED OPTIONS:

-i/--in PATH
    Read input shapefile from PATH. PATH may identify any basic shapefile part
    (.shp, .shx, or .dbf) or the base name (minus suffix), but all three parts
    must be present. Only xy polygon shapefiles are supported.

-o/--out PATH
    Write OpenSCAD script to file at PATH. If PATH is a single hyphen character
    ("-"), the script is written to standard output.

ATTRIBUTE OPTIONS:

Features are extruded according to their attribute value.

-d/--default VALUE
    Set the default attribute value. Default values are used if no --attribute
    field is specified or in place of any null attribute values encountered.
    The default VALUE is 0.

-a/--attribute FIELD
    Read attribute values from the named FIELD. The attribute field type must
    be numeric (integer or double).

-n/--names FIELD
    Label attribute value definitions in the output OpenSCAD script using names
    read from the named FIELD.

--sort
    Sort features by name. No effect if no name field is specified.

Use these options to explicitly set fixed bounds for the extrusion. This is
useful to ensure that multiple models (representing a time series, for example)
are output at the same scale and are therefore comparable.

-l/--lower VALUE
    Set the lower bound of the extrusion - the "floor" height. The default
    VALUE is the minimum value of the attribute.

-u/--upper VALUE
    Set the upper bound of the extrusion - the "ceiling" height. The default
    VALUE is the maximum value of the attribute.

OUTPUT SIZE OPTIONS:

Use these options to constrain the size of the output model. Size values
are in output units, typically interpreted to be millimeters.

-x VALUE
    Features will be scaled to largest size that fits within VALUE output
    units in the X dimension. Defaults to actual X extent of input features.

-y VALUE
    Features will be scaled to largest size that fits within VALUE output
    units in the Y dimension. Defaults to actual Y extent of input features.

-z VALUE
    Extrusion will be scaled so the --upper value would not exceed VALUE
    output units in the Z dimension. Defaults to smaller of X and Y limit. 

--inflation FACTOR
    Scaling FACTOR applied to all features to ensure corners overlap rather
    than coincide. Should be greater than or equal to 1. Defaults to 1.
    OpenSCAD STL export of some maps may fail unless inflation is applied.
    A neglible inflation factor such as 1.0001 is typically sufficient.

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
