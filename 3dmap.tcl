#!/usr/bin/tclsh

lappend auto_path /home/anoved/Repos/shapetcl
package require shapetcl

# usage: 3dmap SHAPEFILE ATTRNAME

# BASE is in output units; it is thickness of base below everything
set BASE 1



# FLOOR and CEIL are display range of attribute values.
# must be <= and >= attribute min and max, respectively.
# By default, they are set to min and max.

# linear_extrude height=0 actually yields height=100; whups
# so, be wary of case where {BASE = 0 && FLOOR = min},
# where the actual HEIGHT of the MIN value unit extrusion could be 0,
# as it will be extruded to 100 instead. One solution: enforce nonzero base height.
# (for clarity, base section could be xy scaled a bit for a flange?)



# cap sets height of CEIL in output units.
# by default, scale is set to match.
# if scale is set otherwise, it overrides cap.
set CAP 10
#set SCALE 0

proc coordlist {coords} {
	set cl [list]
	foreach {x y} [lrange $coords 0 end-2] {
		lappend cl [format {[%s, %s]} $x $y] 
	}
	return [join $cl ",\n"]
}

proc attrminmax {shp attr count} {
	
	set min [$shp attr read 0 $attr]
	set max $min
	
	for {set i 1} {$i < $count} {incr i} {
		set val [$shp attr read $i $attr]
		if {$val < $min} {
			set min $val
		}
		if {$val > $max} {
			set max $val
		}
	}
	
	return [list $min $max]
}

set shp_path [lindex $argv 0]
set attrname [lindex $argv 1]

# open the shapefile
set shp [::shapetcl::shapefile $shp_path]

# get number of elements in shapefile
set count [$shp info count]

# get id of requested attribute field
set attr [$shp fields index $attrname]

lassign [attrminmax $shp $attr $count] min max

set FLOOR $min
set CEIL $max
set SCALE [expr {double($CAP) / double($CEIL)}]
#puts stderr "cap: $CAP"
#puts stderr "ceil: $CEIL"
#puts stderr "scale: $SCALE"

# find center of bounding box and translate everything to 0, 0 origin
lassign [$shp info bounds] xmin ymin xmax ymax
set xloc [expr {($xmax + $xmin) / -2}]
set yloc [expr {($ymax + $ymin) / -2}]

set xsize [expr {$xmax - $xmin}]
set ysize [expr {$ymax - $ymin}]

puts "union() {"

# conditional, if rectangular base is desired; otherwise, base is just bottom bit of extrusion
puts [format "cube(size=\[%s, %s, %s\], centered=true);" $xsize $ysize $BASE]

puts [format "translate(\[%s, %s, 0\]) {" $xloc $yloc]

# process each shape
for {set i 0} {$i < $count} {incr i} {
	
	# extrusion height, WITH FUDGE
	set value [$shp attr read $i $attr]
	set height [expr {$BASE + ($SCALE * ($value - $FLOOR))}]
	
	# fudge fix for 0 height extrusions being extruded 100 units
	if {$height == 0} {
		set height 0.01
	}
	
	# assume all polygon components are outer rings 
	set coords [$shp coord read $i]
	
	foreach c $coords {
		puts [format "linear_extrude(height=%f)" $height]
		puts [format "polygon(points=\[\n%s\]);" [coordlist $c]]
	}
}

puts "}"
puts "}"

$shp close

# substract "scale bar" rings (slightly scaled-down inverted cross sections?)
# at uniform intervals, starting at BASE height and SCALE * interval
