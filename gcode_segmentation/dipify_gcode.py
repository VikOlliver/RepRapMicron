#!/usr/bin/env python3
# dipify_gcode.py - Revision 0.04
#
# A tool to process GCODE, subdividing toolpaths below a safe Z height into smaller segments.
# It moves the tool to safe Z height, touches down to original Z, and returns to safe Z
# for each segment. After a configurable number of points, it simulates a dip probe operation.
# This accepts GCODE made on a scale of 1mm = 10 microns and converts to 1mm = 1 micron
#
# Copyright (C) 2025 Vik Olliver
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

import argparse
import sys
import math

# Configuration parameters
SAFE_Z = 30.0   # Safe Z height over layers when moving around with the probe
DIP_SAFE_Z = 200.0   # Safe Z height when dipping (must clear dip reservoir edge)
FAST_Z = 15000  # Fastest speed we want to move Z axis
SEGMENT_LENGTH = 8  # Length of segments (def 8)
PROBE_POINT_LIMIT = 30  # Number of points before calling dip_probe(). Set to zero for no dip (def 15)
# Location of the dipping reservoir
RESERVOIR_X = 0
RESERVOIR_Y = 0
RESERVOIR_Z= 13
SCALE_FACTOR=10
uv_enabled = True # Usually you will want this enabled, but I put this here for testing.

# NOTE: Not implemented yet.
def parse_arguments():
    parser = argparse.ArgumentParser(
        description="Convert PrusaSlicer GCODE into GCODE dots for plotting or engraving.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("input", help="Input PNG file (use '-' to read from stdin)")
    parser.add_argument("-o", "--output", help="Output GCODE file (use '-' for stdout)", default="-")
    parser.add_argument("-d", "--distance", help="Distance per pixel in CNC units", type=float, default=30.0)
    parser.add_argument("--safe-z", help="Safe travel height in mm", type=float, default=50.0)
    parser.add_argument("--draw-z", help="Drawing/contact height in mm", type=float, default=0.0)
    parser.add_argument("--dipify", help="Dip probe after this many pixels (>=0)", type=int, default=-1)   

    return parser.parse_args()


# NOTE: ??? Flaw in algorithm. If the object is tallet than DIP_SAFE_Z we'll have a collision!
def move_probe_to_reservoir(current_position,output_stream):
    """
    Move the probe to the reservoir. Does not dip. Used for dipping and when turning on the UV
    to put the probe in a location where it will not be solidified.
    """
    output_stream.write(f"G1 Z{max(DIP_SAFE_Z,current_position[2]):.3f} F{FAST_Z:.3f} ; Moving to dip-safe Z\n")
    output_stream.write(f"G0 X{RESERVOIR_X:.3f} Y{RESERVOIR_Y:.3f} ; Moving to reservoir\n")         

def dip_positioned_probe(current_position,output_stream):
    """
    Just dip the probe in the reservoir. This must only be called when the probe is in place.
    """
    output_stream.write(f"G1 Z{RESERVOIR_Z:.3f} F{FAST_Z:.3f} ; Dip the probe\n")
    output_stream.write(f"G1 Z{DIP_SAFE_Z:.3f} F{FAST_Z:.3f} ; Move probe above reservoir\n")
    output_stream.write(f"G0 X{current_position[0]:.3f} Y{current_position[1]:.3f} ; Return probe\n")
    # Note: The caller will sort the Z height out

def dip_probe(current_position,output_stream):
    """
    Move the probe to the reservoir and dip the tip. Restore XY probe position after dip.
    """
    move_probe_to_reservoir(current_position,output_stream)
    dip_positioned_probe(current_position,output_stream)
    # Note: The caller will sort the Z height out

def expose_to_uv(current_z,output_stream):
    """
    While slowly raising the probe 10 microns, leave the UV LED on. This gives us
    the LED exposure time.
    """
    if uv_enabled:
      # Now turn on the UV LED, and do a move that will take 10 seconds while the UV gels a bit
      output_stream.write(f"M8 ; UV On, slow move\n");
      output_stream.write(f"G1 Z{max(DIP_SAFE_Z,current_z)+10} F10\n");
      # OK, LED can go off now
      output_stream.write(f"M9 ; UV Off\n");


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
    param_str = " ".join(
        f"{k}{v:.5f}" for k, v in params.items() if k != "A"
    )

    line = f"{command} {param_str}".strip()

    if comment_part:
        line += f" ;{comment_part}"

    return line

def distance_xy(point1, point2):
    """
    Calculates the Euclidean distance between two points in the XY plane.
    """
    return math.sqrt((point1[0] - point2[0]) ** 2 + (point1[1] - point2[1]) ** 2)

def segment_path (start, end, segment_length):
    """
    Breaks a line segment into smaller segments of specified length, considering only XY distance.
    """
    segments = []
    total_distance = distance_xy(start, end)
    if total_distance <= segment_length:
        return [end]

    num_segments = math.ceil(total_distance / segment_length)
    dx = (end[0] - start[0]) / num_segments  # Increment in X
    dy = (end[1] - start[1]) / num_segments  # Increment in Y

    for i in range(1, num_segments + 1):
        segment_point = [
            start[0] + i * dx,
            start[1] + i * dy,
            start[2]  # Maintain the original Z height from the input
        ]
        segments.append(segment_point)

    return segments

def process_gcode(input_stream, output_stream):
    """
    Processes GCODE lines and breaks toolpaths into segments that can be drawn with a dip pen
    """
    current_safe_z = SAFE_Z
    current_position = [0.0, 0.0, current_safe_z]
    current_layer = 0    # The max height at which we consider we're in the current layer.
    last_probe_position = None
    point_count = PROBE_POINT_LIMIT  # Ensure the probe gets dipped before first point is plotted.
    printed_something = False        # We don't expose the layer before we've printed something

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

        # Line contains only a comment. If it indicates layer change, expose layer and change safe Z
        if command is None:
          output_stream.write(f"; {comment}\n")
          if comment.startswith("Z:"):
            possible_new_layer_ht = None
            try:
              possible_new_layer_ht = float(comment[2:])*SCALE_FACTOR
            except ValueError:
              pass
            # If we detected a Z value (a) expose the previous layer, and (b) adjust safe Z height.
            if possible_new_layer_ht is not None:
              current_safe_z = possible_new_layer_ht + SAFE_Z
              current_layer = possible_new_layer_ht
              # Now move the probe over the reservoir to protect it from UV
              move_probe_to_reservoir(current_position,output_stream)
              if printed_something:
                # If we have printed something, expose it.
                # Note: on first layer start there is no output yet!
                expose_to_uv(current_position[2],output_stream);
              # May as well dip the probe while we're here...
              # We're dipping. Reset the dip count
              point_count = 0
              # Do the dip
              dip_positioned_probe(current_position,output_stream)
          elif comment.startswith("*END"):
            # This is the end of the print. We need to move to the reservoir location and do a UV exposure
            move_probe_to_reservoir(current_position,output_stream)
            expose_to_uv(current_position[2],output_stream);
            # Nothing else *should* happen after this except turnign the motors off.
            # If it does it's out of spec.
            # End of comment handler
          continue

        if command == "G1":
            # Ah, a G1 movement. We're interested in those. Where are we going?
            new_position = [
                params.get("X", current_position[0]),
                params.get("Y", current_position[1]),
                params.get("Z", current_position[2])
            ]

            # Only modify the command if we're close to the work surface.
            if new_position[2] <= current_layer:
                segments = segment_path(current_position, new_position, SEGMENT_LENGTH)

                # Flag indicating we are definitely at safe height, to raise probe for first move.
                segment_move_flag = 0
                for segment in segments:
                    # Check if this point is sufficiently far from the last probe point
                    if last_probe_position is None or distance_xy(last_probe_position, new_position) >= SEGMENT_LENGTH / 2:
                      # We have not probed near this point before. Output it.
                      # Move to safe Z height if not there already
                      if segment_move_flag == 0:
                        output_stream.write(f"G1 Z{current_safe_z:.3f} F{FAST_Z:.3f} ; Moving to safe Z\n")

                      # We're probing a new point. Do we need to check probe dipping?
                      if PROBE_POINT_LIMIT > 0:
                        # See if we've worn all the ink off and need to dip
                        point_count += 1
                        if point_count >= PROBE_POINT_LIMIT:
                            dip_probe(segment,output_stream)
                            # Reset the point count and move to skimming height as we are now at SAFE_Z
                            point_count = 0
                            output_stream.write(f"G1 Z{(segment[2]+10):.3f} F{FAST_Z:.3f} ; Move to skim\n")


                      # Move to segment point
                      output_stream.write(f"G0 X{segment[0]:.3f} Y{segment[1]:.3f} F{FAST_Z:.3f} ; Moving to segment point\n")
                      # Touch down to skimming height if still at SAFE_Z
                      if segment_move_flag == 0:
                        output_stream.write(f"G1 Z{(segment[2]+10):.3f} F{FAST_Z:.3f} ; Move to skim\n")
                      output_stream.write(f"G1 Z{segment[2]:.3f} F900 ; Touching down gently\n")
                      output_stream.write(f"G1 Z{segment[2]+10:.3f} F{FAST_Z:.3f} ; Raise probe slightly\n")
                      segment_move_flag = 1 # No longer need to move to SAFE_Z before printing anything
                      printed_something = True
                      # Set the last probed position so we don't touch near it again.
                      last_probe_position = segment
                # We have printed a segment of some kind.
                # If we've printed a dot, return to a safe Z height and note new line start position
                if segment_move_flag != 0:
                  output_stream.write(f"G1 Z{current_safe_z:.3f} F{FAST_Z:.3f} ; Returning to safe Z.\n")
                current_position = new_position
            else:
                # We're above Safe Z, so just execute the existing GCODE with any scaling
                current_position = new_position
                output_stream.write(reconstruct_gcode(command, params, comment) + '\n')
        else:
            # This is not a G1 code, so just pass it through.
            output_stream.write(line + '\n')


def main():
    """
    Main function to handle input and process GCODE.
    """
    usage = (
        "Usage: dipify_gcode.py [input_file] [output_file]\n"
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

    outfile.write('; File processed by dipify_gcode.py\n')
    process_gcode(infile, outfile)

    # If not using standard input, close the files
    if input_file:
      infile.close()
    if output_file:
      outfile.close()

if __name__ == "__main__":
    main()
