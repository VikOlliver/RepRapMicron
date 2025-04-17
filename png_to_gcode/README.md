# png_to_gcode Utility

This takes a PNG image and parses it pixel by pixel. It creates GCODE that moves a CNC tool head (or μRepRap probe) to probe either dark or light pixels.

It takes and outputs either from files or STDIO, and light/dark/movement/height etc. are all configurable from the command line.

use png_to_gcode -h for detailed help.
