# **M**icron **A**ccurate **U**niversal **S**ystem- “Maus”

## Overview
Maus is a collection of micron-accurate components based on 3D printed flexures. These can be combined into a multi-axis motion stage allowing a probe (or probes) to be manipulated.

The probe can be manoeuvred around a standard 25mm x 75mm glass microscope slide. Micron-level movement in the default configuration is expected to be possible inside a 4mm cube, and non-destructive movement (basically to get the probe out of the way) inside an 8mm cube. The probe can be used as a dip pen for depositing UV resin and other liquids from a reservoir on the slide. The probe is conductive and can be used to scan conductive objects via a ground wire on the slide holder.

A window in the stage allows UV exposure of the resin from underneath without illuminating the reservoir. Motion is achieved with a 400 step NEMA17 stepper motor on each axis driver, and these are controlled by any method convenient for the user.

The intention is that the probe will also be used to manipulate or even operate micron-scale items.

## Build
The *maus* directory contains three main Maus OpenSCAD build files, a design for a probe box, and the deprecated XY Table design:

**maus_axis_driver.scad** has the flexure-based precision axis driver design that is driven by a NEMA17 stepper motor.

**maus_complementary.scad** is the XY Table and stage design using complementary flexures. These have the great advantage that they do not move much in the Z axis when moving in the X & Y axes. Also contains clamp design for cylindrical USB miscroscopes.

**flexure_linear_coupling.scad** is a model for a couping that press fits on a NEMA17 motor shaft, and given sufficient downward pressure can hold a modified M3x50 screw. The screw has the head filed down in a drill so that it is narrower in diameter than the narrowest axis of an M3 nut, and the nut is screwed all the way down to the head, where it is secured with Loktite. The tapered hexagonal hole in the top of the coupling holds on to the nut.

**probe_electrolysis_grip.scad** provides a convenient jig for making micron probe tips from 28ga stainless steel or nichrome wire. 5% salt solution is used as the electrolyte, and the extremely simple process is described at [https://www.printables.com/model/874566](https://www.printables.com/model/874566).

## Deprecated

**maus_stage_deprecated.scad** Original XY Table design, now deprecated. Has at its bottom three *if (true/false)* statements used to print a selected set of parts for either an axis driver (you probably want three of those), a slide probe assembly, or an XY Table. It uses SCAD files included from the ../include directory.

**metriccano_flexures.scad** Deprecated. Has the 2-way flexure joints used for an XY Table in it, and is included by maus_stage_deprecated.scad . This should probably be in the include directory, but there are too many dependencies, I haven't figured out a nice way yet, and deprecated anyway.

## Recommended Software
To control the stepper motors, an Arduino running GRBL and a 3-axis GRBL stepper shield are adequate. GCODE can be conveniently output by 3D printer or CNC programs, though it is recommended that a scale of 1mm to 1 micron is used to avoid floating point errors. The author uses an Arduino Mega running GRBL and driving a RAMPS1.4 3D printer control board. To generate the GCODE they use Inkscape to create SVG files, convert those to GCODE with jscut, and use cncjs as a control console. There are also a number of Python scripts in the repository for converting a PNG file to GCODE coordinates, and to act as a processing filter to allow PrusaSlicer to create μRepRap GCODE.

## Documentation
There is some in the Github Wiki, though I've been busy making it work and haven't written it all yet. Experiences are logged on the RepRap Blog http://blog.reprap.org (yes, that is http, the project is rather old).

Hopefully there will be some videos made, as we've just had a videographer volunteer. But Everything Open conference presentation is near, and planning has to be done etc.

## Todo
The next big thing is to get the UV LED curing a layer automatically, and then building a second layer on top of it.

A callibration test part for determining the flexibility of flexures printed in specific plastics has been designed, but it has not been quantitatively described.

## Printing
The parts are designed to be printed from quality PLA with no brim or support. Some printers may have difficulty printing the long beams, in which case use a brim for only those parts. The design expects 0.2mm layers with perimeters and wall thicknesses optimised for strength. As a starting point, use 4 walls and 20% infill. The author uses a Prusa Mk4 with a 0.4mm nozzle loaded with either eSun PLA+ filament or Diamond Age/Imagin Ingeo PLA. Do not use ASA, PETG, exotic filaments, matt finish, metallic-filled and so forth as these tend to be stiffer and cause the structure to flex undesirably. The height (and thus flexibility) of the flexures can be tuned in the *maus_*.scad* files if specific filaments or materials are required.

## Pre-built STL Files
If you just want to print bits and play with them, the 0.02 version can be found on Printables at [https://www.printables.com/model/1124932](https://www.printables.com/model/1124932) though these are not guaranteed to be up-to-date, and may not work if your filament is particularly flexible or rigid. The V0.03 STL files built by current code are still being tested, but should be released relatively soon.
