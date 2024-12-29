# **M**icron **A**ccurate **U**niversal **S**ystem- “Maus”

## Overview
Maus is a collection of micron-accurate components based on 3D printed flexures. These can be combined into a multi-axis motion stage allowing a probe (or probes) to be manipulated.

# Build
The maus_stage.scad file has at its bottom three if (true/false) statements that can be used to print a set of parts for an axis driver (you probably want three), a slide probe assembly, and an XY Table. It uses files from the ../include directory.

flexure_linear_coupling.scad is a model for a couping that press fits on a NEMA17 motor shaft, and given sufficient downward pressure can hold a modified M3x50 screw. The screw has the head filed down in a drill so that it is narrower in diameter than the narrowest axis of an M3 nut, and the nut is screwed all the way down to the head, where it is secured with Loktite. The tapered hexagonal hole in the top of the coupling holds on to the nut.

probe_electrolysis_grip.scad provides a convenient jig for making micron probe tips from fine nichrome wire. 5% salt solution is used as the electrolyte, and the process is described at [https://www.printables.com/model/874566](https://www.printables.com/model/874566).

## Documentation
There is precious little, mostly because I've been busy making it work and haven't written any yet. Experiences are logged on the RepRap Blog http://blog.reprap.org (yes, that is http, the project is rather old).

## Printing
The parts are designed to be printed from quality PLA with no brim or support. Some printers may have difficulty printing the long beams, in which case use a brim. The design expects 0.2mm layers with perimeters and wall thicknesses optimised for strength. As a starting point, use 4 walls and 20% infill.

## Pre-built STL Files
If you just want to print bits and play with them, a version can be found on Printables at [https://www.printables.com/model/1124932](https://www.printables.com/model/1124932) though these are not guaranteed to be up-to-date, and may need slight tweaking if your filament is particularly flexible or rigid.
