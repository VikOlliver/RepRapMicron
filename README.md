# RepRapMicron (μRepRap)

## Overview

The RepRapMicron Project, or μRepRap, is an extension of the Open Source RepRap 3D printer project that aims to bring micron-scale fabrication into very widespread adoption. The main project page is [here](https://reprap.org/wiki/RepRapMicron). It uses hardware and software familiar to 3D printer developers, and materials that are easily and inexpensively available.

The meaty part is in the "maus" directory, where the OpenSCAD models for a rapidly reconfigurable 3D printed prototype can be found.

At present, the project is in the very early prototyping stages, figuring out the unknown unknowns. This repository holds files that can reasonably be expected to be useful to potential developers/experimenters, but at this stage there are absolutely no guarantees.

## Roadmap

1. Develop a micron-accurate, 3D printable mechanism.
2. Develop a print head for it.
3. Make more of them
4. Reduce further to nanoscale
5. Take over the world


## Directory Structure
### library
A Selection of useful OpenSCAD libraries used in generating "Metriccano" modular components (10mm grid, M3 fasteners), screw holes, motor mounts etc.
### Maus
**M**icron **A**ccurate **U**niversal **S**ystem - OpenSCAD model files for micron precision axis components based on flexures.

The maus directory contains standard axis drivers, XY complementary flexure Table, and probe parts that need screwing down to a solid surface. It can be assembled on a Metriccano baseboard supplied for lasercutting as metriccano_baseboad.svg, or a 11 x 13 hole piece of 10mm pitch perf board.

As assembly documentation is in progress on the Github Wiki. Pictures from a variety of angles are available [here](http://blog.reprap.org/2025/02/maus-c-assembly-photos.html).

## gcode_segmentation
Python code to take GCODE from a 3D printer slicing program such as PrusaSlicer, and break it into GCODE for a series of points that can be invidivually deposited with the probe. There is provision for a routine to "re-ink" the probe tip after a predetermined number of points are deposited.

## png_to_gcode
Python code that reads a PNG bitmap and emits GCODE that will probe a corresponding point on the GCODE-controlled hardware. Pitch, brightness level and so forth can be provided on the command line. Intended for using RepRapMicron in dip-pen mode with bitmap files, but probably has other uses.

### oldGRBLdelta
A python/Zelle Control Panel that drives a GRBL CNC using xyz steppers and uses them to control an OpenFlexure microscope delta stage.

## Contributing
Please do join in. We need everything. Coders, makers, nanoscience experts, materials scientists, 3D printing experts, manual writers, graphics artists, dancers, the works. Well, maybe not the dancers.

The main repository of knowledge is the wiki on the [main project page](https://reprap.org/wiki/RepRapMicron). General updates go on [the blog](http://blog.reprap.org/). There is some coverage on the Facebook RepRap page, and commentary is welcomed.

## Licence
GPL V3 or later

## Project status
Alpha, but functional.
