#!/usr/bin/env python3
# backlash_vernier.py - Revision 0.01
#
# Generates GCODE for visual backlash estimation using a vernier-style pattern.
#
# Two sets of vertical lines are drawn:
#  - First set: right-to-left, increasing spacing
#  - Second set: left-to-right, constant spacing
#
# The pair of lines that visually align indicates backlash magnitude.
#
# Units: 1 mm in GCODE = 1 micron in machine space.
#
# Copyright (C) 2026 Vik Olliver
#
# Licensed under the GNU GPL v3 or later.
#

import sys
import argparse

# ---------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------

SAFE_Z = 45.0	# Height at which probe is sfae to move at speed
DRAW_Z = 0.0	# Expected height where probe hits the surface

FAST_XY = 8000
SLOW_XY = 2000
FAST_Z = 8000
SLOW_Z = 1000

LINE_LENGTH = 200

DELTA = 0.5  # increment per line (microns)
NUM_LINES = 10
BASE_SPACING = 80	# SPacing of fixed set of lines

Y_TOP = 0
Y_BOTTOM = -210  # separation between patterns


# ---------------------------------------------------------------------

def move_safe(output):
    output.write(f"G1 Z{SAFE_Z:.3f} F{FAST_Z:.3f}\n")


def move_to(x, y, output):
    output.write(f"G0 X{x:.3f} Y{y:.3f} F{FAST_XY:.3f}\n")


def lower_probe(output):
    output.write(
        f"G1 Z{(DRAW_Z+2):.3f} F{FAST_Z:.3f}\n"
        f"G1 Z{DRAW_Z:.3f} F{SLOW_Z:.3f}\n"
    )


def raise_probe(output):
    output.write(
        f"G1 Z{(DRAW_Z+2):.3f} F{SLOW_Z:.3f}\n"
        f"G1 Z{SAFE_Z:.3f} F{FAST_Z:.3f}\n"
    )


def draw_vertical_line(x, y_start, y_end, direction, output):
    """
    direction: "up" or "down"
    """

    move_to(x, y_start, output)
    lower_probe(output)

    if direction == "up":
        output.write(f"G1 Y{y_end:.3f} F{SLOW_XY:.3f}\n")
    else:
        output.write(f"G1 Y{y_start:.3f} F{SLOW_XY:.3f}\n")

    raise_probe(output)


# ---------------------------------------------------------------------

def generate_pattern(output, axis="x"):
    move_safe(output)
    move_to(0, 0, output)

    OFFSET = (NUM_LINES - 1) * DELTA / 2

    def draw_line(pos, start, end):
        if axis == "x":
            draw_vertical_line(pos, start, end, "up", output)
        else:
            # rotate 90°: swap X/Y roles
            move_to(start, pos, output)
            lower_probe(output)
            output.write(f"G1 X{end:.3f} F{SLOW_XY:.3f}\n")
            raise_probe(output)

    # -----------------------------
    # Top pattern (reverse direction)
    # -----------------------------
    for i in reversed(range(NUM_LINES)):
        pos = i * BASE_SPACING + i * DELTA
        draw_line(pos, Y_TOP, Y_TOP + LINE_LENGTH)

    # -----------------------------
    # Bottom pattern (forward direction)
    # -----------------------------
    for i in range(NUM_LINES):
        pos = i * (BASE_SPACING + OFFSET)
        draw_line(pos, Y_BOTTOM, Y_BOTTOM + LINE_LENGTH)


# ---------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description="Generate vernier backlash test pattern"
    )

    parser.add_argument(
        "--axis",
        choices=["x", "y"],
        default="x",
        help="Axis to test (default: x)"
    )

    parser.add_argument(
        "--output",
        help="Output file (default: stdout)"
    )

    args = parser.parse_args()

    outfile = sys.stdout
    if args.output:
        outfile = open(args.output, "w")

    outfile.write("; Backlash vernier pattern\n")
    outfile.write(f"; Axis: {args.axis}\n")
    outfile.write("; Units: 1 mm = 1 micron\n\n")

    generate_pattern(outfile, axis=args.axis)

    if args.output:
        outfile.close()

if __name__ == "__main__":
    main()
