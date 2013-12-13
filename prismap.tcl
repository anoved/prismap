package provide prismap 1.0
package require shapetcl
namespace eval prismap {
	namespace export prismap

	package require msgcat
	#namespace import ::msgcat::*
	::msgcat::mcload [file join [file dirname [info script]] {msgs}]
	::msgcat::mcload [file join [pwd] {msgs}]

	
	proc LoadShapefile {} {
		
		variable shp
		
		set shp [::shapetcl::shapefile $shp_path]
		
		set shp_count [$shp info count]
		
		# get bounding box size and centroid offset
		
		set attr [$shp fields index $attr_name]
		
		# get attribute min/max
		
	}
	
	proc PostLoadSetup {} {
		
		# re-validate floor/ceil, if set, against min/max
		
		# set default floor/ceil to min/max
		
		# calculate default scale 
		
	}
	
	proc Process {} {
		
		# union {
		
		# base rect, if on
		
		# translate bbox to origin {
		
		for {set i 0} {$i < $count} {incr i} {
		
			# calculate extrusion height
			set attr_value [$shp attributes read $i $attr]
			set height [expr {$base + (double($scale) * ($attr_value - $floor))}]
			
			# get coordinates; may consist of multiple rings
			set coords [$shp coordinates read $i]
			
			# each outer ring (island) is its own scad polygon
			# inner rings (holes) are expressed as per polygon parameters
			# I need a refresh on how shapefiles/shapetcl handle this in order Do The Right Thing.
			
			# this treats all rings as outer rings.
			# won't "fail" - holes will just be union filled.
			foreach part $coords {
				 # linear_extrude($height)
				 # polygon(points=$part)
			}
		}
		
		# close translate and union }}
		
	}
	
	proc ScaleScoring {} {
		
		# optionally substract "scale bar" perimeter rings from the extrusion at regular intervals
		# starting at $base height
		
	}
	
	proc ParseOptions {argl} {
		
		
		set base   {}
		set floor  {}
		set ceil   {}
		set height {}
		set scale  {}

		for {set a 0} {$a < [llength $argl]} {incr a} {
			set arg [lindex $argl $a]
			
			switch -- $arg {
				-b - --base {
					if {[scan [lindex $argl [incr a]] %f base] != 1} {
						Abort {$arg must be numeric.}
					}
					if {$base < 0} {
						Abort {$arg must be >= 0}
					}
				}
				-f - --floor {
					if {[scan [lindex $argl [incr a]] %f floor] != 1} {
						Abort {$arg must be numeric}
					}
					# must check that floor <= attribute min value
					# must check that floor < ceil
				}
				-c - --ceil {
					if {[scan [lindex $argl [incr a]] %f ceil] != 1} {
						Abort {$arg must be numeric}
					}
					# must check that ceil >= attribute max value
					# must check that ceil > floor
				}
				-h - --height {
					if {[scan [lindex $arg1 [incr a]] %f height] != 1} {
						Abort {$arg must be numeric}
					}
					if {$height <= 0} {
						Abort {$arg must be > 0}
					}
				}
				-s - --scale {
					if {[scan [lindex $argl [incr a]] %f scale] != 1} {
						Abort {$arg must be numeric}
					}
					if {$scale == 0} {
						Abort {$arg must not be 0}
					}
				}
				-i - --in {
					set shapefile [lindex $argl [incr a]]
				}
				-a - --attribute {
					set attribute [lindex $argl [incr a]]
				}
				-h --help {
					PrintUsage
					exit
				}
				-o - --out {
					# output scad file path
					# by default, print to stdout
				}
				-r - --rect {
					# rectangular base mode
				}
				default {
					Abort {unrecognized option $arg}
				}
			}
		}
		
		# check for required arguments (-i and -a)
		
		# re-validate floor/ceil once attributes are loaded 
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
		exit
	}

	ParseOptions $::argv
	Start
}
