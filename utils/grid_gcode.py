#!/usr/bin/env python3
# grid_gcode.py - Revision 0.03
#
# Generates GCODE for drawing a simple calibration grid on the Z=0 plane.
# The probe lifts to SAFE_Z between each line. Lines are drawn in a fixed
# and predictable order: horizontal lines from bottom to top, then vertical
# lines from left to right.
#
# Units assume the same scaling used by dipify_gcode.py:
# 1 mm in GCODE corresponds to 1 micron in machine space.
#
# This tool is intended for early-stage calibration and bring-up of
# micron-scale CNC deposition systems such as RepRapMicron.
#
# Copyright (C) 2026 Vik Olliver
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#

import sys

# ---------------------------------------------------------------------
# Configuration parameters
# ---------------------------------------------------------------------

SAFE_Z = 45.0        # Safe Z height between lines
DRAW_Z = 0.0         # Drawing height

GRID_SIZE = 1000     # Overall grid dimension
LINE_SPACING = 100   # Distance between grid lines
LINE_LENGTH = 1000   # Length of each line

FAST_XY = 8000       # Rapid XY motion speed
SLOW_XY = 4000       # Drawing speed
FAST_Z = 8000        # Z movement speed
SLOW_Z = 1000        # Lift off and touchdown speed for Z

def draw_line(start, end, output_stream):
    """
    Draw a single line at DRAW_Z.
    The probe is assumed to already be at SAFE_Z.
    """

    # Move to start of line
    output_stream.write(
        f"G0 X{start[0]:.3f} Y{start[1]:.3f} F{FAST_XY:.3f} ; Move to line start\n"
    )

    # Lower probe, gently
    output_stream.write(
        f"G1 Z{(DRAW_Z+2):.3f} F{FAST_Z:.3f} ; Lower probe\n"
        f"G1 Z{DRAW_Z:.3f} F{SLOW_Z:.3f} ; Lower probe\n"
    )

    # Draw line
    output_stream.write(
        f"G1 X{end[0]:.3f} Y{end[1]:.3f} F{SLOW_XY:.3f} ; Draw line\n"
    )

    # Raise probe, low liftoff speed
    output_stream.write(
        f"G1 Z{(DRAW_Z+2):.3f} F{SLOW_Z:.3f} ; Raise probe\n"
        f"G1 Z{SAFE_Z:.3f} F{FAST_Z:.3f} ; Raise probe\n"
    )


def generate_grid(output_stream):
    """
    Generate horizontal and vertical grid lines.
    """

    num_lines = int(GRID_SIZE / LINE_SPACING) + 1

    # Move to safe height before starting
    output_stream.write(
        f"G1 Z{SAFE_Z:.3f} F{FAST_Z:.3f} ; Move to safe height\n"
    )

    # Explicit move to origin
    output_stream.write(
        f"G0 X0.000 Y0.000 F{FAST_XY:.3f} ; Move to origin\n"
    )

    # Horizontal lines
    for i in range(num_lines):
        y = i * LINE_SPACING

        start = [0.0, y]
        end = [LINE_LENGTH, y]

        draw_line(start, end, output_stream)

    # Vertical lines
    for i in range(num_lines):
        x = i * LINE_SPACING

        start = [x, 0.0]
        end = [x, LINE_LENGTH]

        draw_line(start, end, output_stream)


def main():
    """
    Entry point for grid generator.
    """

    outfile = sys.stdout
    output_file = None

    if len(sys.argv) > 1:
        output_file = sys.argv[1]

    if output_file:
        outfile = open(output_file, "w")

    outfile.write("; Calibration grid generator\n")
    outfile.write("; Units: 1 mm = 1 micron\n")
    outfile.write("; Expected machine state: homed\n")
    outfile.write(f"; Grid size: {GRID_SIZE}\n")
    outfile.write(f"; Line spacing: {LINE_SPACING}\n")
    outfile.write("\n")

    generate_grid(outfile)

    if output_file:
        outfile.close()


if __name__ == "__main__":
    main()
