#!/usr/bin/tclsh

lappend auto_path /home/anoved/Repos/shapetcl
package require shapetcl

# usage: 3dmap SHAPEFILE ATTRNAME

proc coordlist {coords} {
	set cl [list]
	foreach {x y} [lrange $coords 0 end-2] {
		lappend cl [format {[%s, %s]} $x $y] 
	}
	return [join $cl ","]
}

set shp_path [lindex $argv 0]
set attrname [lindex $argv 1]

# open the shapefile
set shp [::shapetcl::shapefile $shp_path]

# get id of requested attribute field
set attr [$shp fields index $attrname]

# get number of elements in shapefile
set count [$shp info count]

# find center of bounding box and translate everything to 0, 0 origin
lassign [$shp info bounds] xmin ymin xmax ymax
set xloc [expr {($xmax + $xmin) / -2}]
set yloc [expr {($ymax + $ymin) / -2}]

puts [format {translate([%s,%s,0]) } $xloc $yloc]

puts "union() {"

# process each shape
for {set i 0} {$i < $count} {incr i} {
	
	# extrusion height, WITH FUDGE
	set value [$shp attr read $i $attr]
	set height [expr {(0.3 * $value)}]
	
	# assume all polygon components are outer rings 
	set coords [$shp coord read $i]
	
	foreach c $coords {
		puts [format {linear_extrude(height=%f)} $height]
		puts [format {polygon(points=[%s]);} [coordlist $c]]
	}
}

puts "}"

$shp close
