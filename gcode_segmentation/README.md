# RepRapMicron (μRepRap) "Dipify" GCODE Segmentation

## Overview

These are the files used by The RepRapMicron Project, or μRepRap, to create GCODE from an STL or SVG file using PrusaSlicer that will draw the lines with individual dots of resin. Currently only works with one layer.

It uses a scale of 1mm to 1 micron in the PrusaSlicer config, hopefully the same as you have configured your GRBL or other CNC controller to. As it only does the first layer, it is currently advised to only slice the first "8mm" of your object.

## How it works

When you export the sliced model, the prusa_filter.sh bash script takes Prusa's GCODE filename as the first parameter. It is basically there to handle temporary files and call some python. I found it useful for debugging so I left it there.

The dipify_gcode.py will scan the GCODE to find lines drawn below the safe Z height and break that line into segments. These segments are smaller than the resin dot RepRapMicron deposits, so a line of joined dots will be created.

After a given number of dots are deposited, the probe is taken to the reservoir coordinates and dipped in resin. Then it returns to the last point and continues.

The points are sanity checked for proximity, so for things like arcs constructed of many short lines, points are not deposited on top of one another.

## Setting up

Load a new slide into the RepRapMicron, add a thin smear (not a drop) of resin on the foil contact plate right up to the folded over edge of the plate. Do not get resin on the folded part. That is the barrier between the resin and the build area.

Position the probe over the glass slide nearby.

Using your CNC control software move over the resin and do a "Z Touch" with the probe.

Rasie the probe 70 microns or so and move it to an area of glass where you will not be depositing resin. Lower the probe to about 5 microns over the glass, or until it just deposits a droplet of resin in the slide (you'll have to move the probe up and sideways to spot it).

Set this as the Z zero and raise the probe to 70 microns or so again. Move the probe above the resin, lower it until it is in the resin. This is your reservor Z value. Zero X & Y.

Move to the area where you want the centre of your print to be. Note the X & Y coordinates. Zero X & Y.  Do not go too close to the foil or you may drip resin into your print if things go poorly. Do not go too far away from the reservoir, or the movement will take ages. 150-200 microns is far enough.

The negative of the noted X & Y cooridnates are your X & Y reservoir values. Enter the reservoir X Y Z coordinates into the dipify_gcode.py file as RESERVOIR_[XYZ] and save. Slice your file in PrusaSlicer and export the GCODE.

Load the GCODE into your CNC control software and run.

Fine tuning segment sizes and number of points per dip is left as an exercise to the diligent student.
