# png_to_gcode Utility

# Overview
This takes a PNG image and parses it pixel by pixel. It creates GCODE that moves a CNC tool head (or μRepRap probe) to probe either dark or light pixels.

It takes and outputs either from files or STDIO, and light/dark/movement/height etc. are all configurable from the command line.

use png_to_gcode -h for detailed help.

## Improvements
This needs code to optionally implement a "dip pen" function like gcode_segmentation where the probe is dipped in a resin reservoir after however many points are plotted. In fact, multiple reservoirs might be useful, allowing pixels in various colours to be plotted using different resins (obvious complexities like cleaning the probe tip are left as an excercise to the individual). Perhaps this should be in a shared library?

## Rationale
The idea for this emerged because of the gcode_segmentation 3D printer filter. Why, I thought, go to all the trouble of making vectors and turning them into pixels when you can just create a pixel map? It has a drawing height programmable from the command line, so in theory could do multiple layers. At the very least people are goign to print bitmap logos with it.
