# Prismap

This script generates an [OpenSCAD](http://www.openscad.org/) model of a polygon shapefile with features extruded proportional to designated attribute values. Using OpenSCAD, the extruded "prism map" can be exported to STL format suitable for 3D printing. It is a work in progress.

The end goal is to generate prism map templates configurable with [MakerBot Thingiverse Customizer](http://www.thingiverse.com/apps/customizer).

## Example

Documentation and additional examples forthcoming.

![example prismap model](examples/screenshot.png)

The model display above was generated with the following options:

	./prismap.tcl                   \
	    --in examples/northeast.shp \
	    --attribute Measure         \
	    --out examples/example.scad \
	    --height 5                  \
	    --base 0.1                  \
	    --floor                     \
	    --lower 0                   \
	    --upper 30                  \

Note that this example includes disconnected "island" features that may be too small to print successfully. Some prep work to prune unnecessary detail will typically be needed to prepare shapefiles for printing.

## Prerequisites

- [Shapetcl](https://github.com/anoved/Shapetcl/)

## License

Prismap is freely distributed under an open source MIT License:

> Copyright (c) 2013 Jim DeVona
> 
> Permission is hereby granted, free of charge, to any person obtaining a copy of
> this software and associated documentation files (the "Software"), to deal in
> the Software without restriction, including without limitation the rights to
> use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
> the Software, and to permit persons to whom the Software is furnished to do so,
> subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
> FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
> COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
> IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
> CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

