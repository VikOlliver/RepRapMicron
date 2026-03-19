# RepRapMicron (μRepRap) Utilities

## Overview

This directory contains a number of utilites for aligning and calibrating the μRepRap axes.

## backlash_vernier.py

Creates a GCODE file for determining backlash on either the X (default) or Y axis. Use --help for details. Intended to be used with a probe engraving a marker substrate.

The default settings draw two sets of lines, one drawn away from the origin at a spacing increasing by 0.5μm each time, the other drawn towards the origin at constant spacing.

By observing the point at which the lines appear to align, the amount of backlash can be determined. Remember that backlash is occurring in both sets of lines in opposite directions.

## grid_gcode.py

Creates GCODE to draw a grid, default settings 10 x 10 squares of 100μm. THe grid is created using full-length lines across the grid rather than by drawing each square individually.
Useful for determining overall behaviour of the axes when engraving with the probe on a marker substrate.

## levelling_probe.py

Directly drives GCODE-based CNC through a USB serial port. μRepRap is fitted with a Touch Plate - a conductive flat slide connected to one side of the Z Touch CNC input.

This console-based utility does a simple probe on an area (by default 1mm on each side) and indicates the highest corner, lowest corner, and the overall height variation.

Given the accuracy of a foil-covered slide, a height variation of under 4μm is considered reasonable.

It is advisable to run this utility serveral times before relying on any given values because the probe physically interacts with the surface and it may take a few passes for things to stabliize.

The wider the area covered, the more accurate overall levelling will be.
