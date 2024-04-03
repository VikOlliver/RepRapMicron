# RepRapMicron (μRepRap)

## Overview

The RepRapMicron Project, or μRepRap, is an extension of the Open Source RepRap 3D printer project that aims to bring micron-scale fabrication into very widespread adoption. The main project page is [here](https://reprap.org/wiki/RepRapMicron). It aims to use hardware and software familiar to 3D printer developers, and materials that are easily and inexpensively available.

At present, the project is in the very early prototyping stages, figuring out the unknown unknowns. This repository holds files that can reasonably be expected to be useful to potential developers/experimenters, but at this stage there are absolutely no guarantees.

## Roadmap

1. Develop a micron-accurate, 3D printable mechanism.
2. Develop a print head for it.
3. Make more of them
4. Reduce further to nanoscale
5. Take over the world


## Files
The main python file is deltacontrol.py which uses the Zelle portable python graphics library. Just copy graphics.py into the same directory along with the other .py files.

The Control Panel drives a GRBL CNC using xyz steppers and uses them to control an OpenFlexure microscope delta stage. I've modified my GRBL config to home x, y and z simultaneously. The GRBL setup I've used is included. I used [GRBL-Servo](https://github.com/robottini/grbl-servo) and a RAMPS board as my controller, but it should work with other GRBL controllers

## Assembly

3D model files modified or generated for μRepRap are here:
https://www.printables.com/model/827788-probe-arm-and-endstop-switch-feet-for-openflexure
https://www.printables.com/model/797699-openflexure-delta-microscope-mods-to-fit-nema17-st

You will need the delta stage file delta_stage_multipath_microscope_reinforced.stl to fit the probe parts to.

Other parts and assembly details for the stage are found on the [OpenFlexure site](https://build.openflexure.org/openflexure-delta-stage/v1.2.2/pages/index_reflection.html). Only the stage assembly itself is required but you will at least need their 'O'-ring insertion tool. The fancy base and Raspberry Pi components are not needed.

## Contributing
Please do join in. We need everything. Coders, makers, nanoscience experts, materials scientists, 3D printing experts, manual writers, graphics artists, dancers, the works. Well, maybe not the dancers.

The main repository of knowledge is the wiki on the main project page. General updates go on [the blog](http://blog.reprap.org/). There is some coverage on the Facebook RepRap page.

## License
Everything possible is under the GPL.

## Project status
Pre-pre-alpha.
