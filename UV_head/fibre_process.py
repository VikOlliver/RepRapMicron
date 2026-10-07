#!/usr/bin/env python3
# fibre_process.py - Revision 0.01
#
# A tool to process GCODE, strip out anything to do with extruder speed or things our
# GRBL implementation does not understand. Any extruding causes the Coolant Mist (M7)
# command to be issued, which activates a UV source in the probe tip and cures resin.
# If no extrusion is done during a move, the LED is turned off.
#
# It also clamps the maximum Z speed. This may not be necessary.
#
# This accepts GCODE made on a scale of 1mm = 10 microns and converts to 1mm = 1 micron
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# TODO
#
# Parse args properly using argparse


import argparse
import sys
import math

# Configuration parameters
FAST_Z = 8000  # Fastest speed we want to move Z axis
SCALE_FACTOR=10

# NOTE: Not implemented yet.
def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Convert PrusaSlicer GCODE into GCODE with ",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("input", help="Input GCODE file (use '-' to read from stdin)")
    parser.add_argument("-o", "--output", help="Output GCODE file (use '-' for stdout)", default="-")

    return parser.parse_args()

def parse_gcode_line(line,scaling):
    """
    Parses a line of GCODE into a dictionary of commands and their values.
    Preserves any trailing comments.
    scaling - multiplies all input command values by this factor
    """
    parts = line.split(';', 1)  # Split into GCODE and comment
    gcode_part = parts[0].strip()
    comment_part = parts[1].strip() if len(parts) > 1 else ""

    if not gcode_part:  # Line contains only a comment
        return None, {}, comment_part

    tokens = gcode_part.split()
    command = tokens[0]
    params = {token[0]: float(token[1:])*SCALE_FACTOR for token in tokens[1:]}
    return command, params, comment_part

def reconstruct_gcode(command, params, comment_part):
    """
    Takes the parsed output from parse_gcode_line and turns it back
    into a GCODE string again.
    But it keeps the scaling and throws away any attempt to move A axis (extruder)
    """
    modified_parts = []

    for k, v in params.items():
        if k == "A":
            continue  # skip A-axis entirely

        if k == "F":
            v = min(FAST_Z, v)  # Clamp speed to max Z speed

        modified_parts.append(f"{k}{v:.5f}")

    param_str = " ".join(modified_parts)
    line = f"{command} {param_str}".strip()

    if comment_part:
        line += f" ;{comment_part}"

    return line


def process_gcode(input_stream, output_stream):
    """
    Processes GCODE lines and corrects scaling etc.
    """
    
    # Start with the LED turned off in case user forgot ...
    output_stream.write("M9 ; LED off\n");

    # Keep track of whether we switched the optical probe on or not
    probe_led_on = False

    for line in input_stream:
        line = line.strip()
        # Just pass blank lines through
        if not line:
          output_stream.write(line + '\n')
          continue

        # Strip out all "M" codes
        if line.startswith('M') == True:
          continue

        # Skip any attempts to move the A axis
        if line.startswith('G1 A') == True:
          continue

        # Parse the next GCODE line (Scaling of 1 for now)A
        command, params, comment = parse_gcode_line(line,1.0)

        # Line contains only a comment. Ignore and pass through.
        if command is None:
          output_stream.write(f"; {comment}\n")
          continue

        # This is a command. Does it use the extruder?
        uses_extruder = False
        for k, v in params.items():
            if k == "A":
                # Technically it uses the extruder. However, it may be reversing the filament.
                if v > 0:
                    uses_extruder = True
        
        # If we're moving, see if we should have the probe LED on or not to set the resin.
        if line.startswith('G1'):
            # If we're using the extruder and the probe LED is off, turn it on
            if uses_extruder:
                if not probe_led_on:
                    output_stream.write("M7 ; LED on\n");
                    probe_led_on = True;
            else:
                # If not using the extruder and it's on, turn it off
                if probe_led_on:
                    output_stream.write("M9 ; LED off\n");
                    probe_led_on = False;
        
        output_stream.write(reconstruct_gcode(command, params, comment) + '\n')

    # Make damn sure the LED is turned off.
    output_stream.write("M9 ; LED off\n");



def main():
    """
    Main function to handle input and process GCODE.
    """
    usage = (
        "Usage: fibre_process.py [input_file] [output_file]\n"
        "\n"
        "If no input_file is provided, reads from standard input.\n"
        "If no output_file is provided, writes to standard output.\n"
    )

    if len(sys.argv) > 1 and ("-h" in sys.argv or "--help" in sys.argv):
        print(usage)
        sys.exit(0)

    infile = sys.stdin  # Default to standard input and output
    outfile = sys.stdout
    input_file = None
    output_file = None

    # Ugly argument parser to get first input GCODE filename, then the output one.
    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    if len(sys.argv) > 2:
        output_file = sys.argv[2]

    # Try to open the IO.
    if input_file:
        infile = open(input_file, 'r')

    if output_file:
        outfile = open(output_file, 'w')

    outfile.write('; File processed by fibre_process.py\n')
    process_gcode(infile, outfile)

    # If not using standard input, close the files
    if input_file:
      infile.close()
    if output_file:
      outfile.close()

if __name__ == "__main__":
    main()

