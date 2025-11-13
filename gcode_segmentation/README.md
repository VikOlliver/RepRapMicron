# RepRapMicron (μRepRap) "Dipify" GCODE Segmentation

## Overview

These are the files used by The RepRapMicron Project, or μRepRap, to create GCODE from an STL or SVG file using PrusaSlicer that will draw the lines with individual dots of resin. Currently only works with one layer.

It is designed to emit GCODE on a scale of 1mm to 1 micron in the PrusaSlicer config, hopefully the same as you have configured your GRBL or other CNC controller to. Because PrusaSlicer cannot cope with print widths and layer heights on this scale, a scaling factor (set to 10 by default) lets you work on a scale of 1mm to 10 microns. Note that the scaling factor applies to both distance and speed.

## How it works

When you export the sliced model, the prusa_filter.sh bash script takes Prusa's GCODE filename as the first parameter. It is basically there to handle temporary files and call some python. I found it useful for debugging so I left it there.

The dipify_gcode.py looks for the first "Layer" comment in the GCODE and uses that to determine the layer height. It then scans the GCODE to find lines drawn below the safe Z height and breaks those line into segments. The probe is lowered to the current layer height to touch the print bed and leave a resin dot. These segments are smaller than the resin dot RepRapMicron deposits, so a line of joined dots will be created.

Some GCODE such as A axis movement and M commands are discarded.

After a given number of dots are deposited, the probe is taken to the reservoir coordinates and dipped in resin. A UV LED on the coolant output of the CNC controller is briefly turned on while the probe is in the resin reservoir (note: this is protected from the UV). Then it returns to the last point and continues.

The points are sanity checked for proximity, so for things like arcs constructed of many short lines, points are not deposited on top of one another.

At the start of each layer other than the first, the probe is dunked in the resin and the UV LED is turned on to solidify the layer.

At the end of the GCODE the script expects to find a "; *END" comment, at which point it will safely move the probe into the reservoir and do a final and longer UV exposure.

## Notable WeirdnessCompared To Conventional Extruders

FFF extruders squirt plastic down from a known height. The RepRapMicron deposits resin at the layer height, with the resin buildup above the probe tip. To work around the slicer implications, print the first layer with a negligible layer height.

FFF Extruders will drop their exudate down towards the bed, and if the layer height is set a bit tall a loosely consolidated print will result. If the RepRapMicron probe does not reach a previous layer when attempting a second layer it will not deposit any resin there or on subsequent layers and you get no output at all.

## Setting up

Load a new slide into the RepRapMicron, add a thin smear (not a drop) of resin on the foil contact plate right up to the folded over edge of the plate. Do not get resin on the folded part. That is the barrier between the resin and the build area.

Position the probe over the glass slide nearby.

Using your CNC control software move over the resin and do a "Z Touch" with the probe.

Raise the probe 100 microns or so and move it to an area of glass where you will not be depositing resin. Lower the probe to about 5 microns over the glass, or until it just deposits a droplet of resin in the slide (you'll have to move the probe up and sideways to spot it).

Set this as the Z zero and raise the probe to 100 microns or so again. Move the probe above the resin, lower it until it is in the resin. This is your reservor Z value, typically around 25μm and once determined seldom needs adjustment. Reservoir X and Y are variables in the script, but it is very convenient to arrange things so that the reservoir is at X=0, Y=-1000.

Do not get the probe too close to the reservoir edge or the UV light will solidify resin on the probe.

Load the GCODE into your CNC control software and run, finger poised over the HALT switch in a distrustful manner.

Fine tuning segment sizes and number of points per dip is left as an exercise to the diligent student.
