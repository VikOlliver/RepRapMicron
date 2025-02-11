#!/usr/bin/env python3
# dipify_gcode.py - Revision 0.03
#
# A tool to process GCODE, subdividing toolpaths below a safe Z height into smaller segments.
# It moves the tool to safe Z height, touches down to original Z, and returns to safe Z
# for each segment. After a configurable number of points, it simulates a dip probe operation.
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
# Add real code to move to the resin reservoir
# Tidy up SAFE_Z and Z probing so that multiple layers can be implemented
# Strip off extruder parameters from the GCODE too



import sys
import math

# Configuration parameters
SAFE_Z = 40.0  # Safe Z height
SEGMENT_LENGTH = 15.0  # Length of segments
PROBE_POINT_LIMIT = 10  # Number of points before calling dip_probe()

def dip_probe(current_position):
    """
    Dummy function to simulate probing. Save and restore tool position.
    """
    print(f"G1 Z{SAFE_Z:.3f} ; Moving to safe Z before dipping")
    print(f"; Saving tool position: X{current_position[0]:.3f} Y{current_position[1]:.3f} Z{current_position[2]:.3f}")
    print("; Probe dipped.")
    print(f"G1 Z{SAFE_Z:.3f} ; Restoring tool position to safe Z")

def parse_gcode_line(line):
    """
    Parses a line of GCODE into a dictionary of commands and their values.
    Preserves any trailing comments.
    """
    parts = line.split(';', 1)  # Split into GCODE and comment
    gcode_part = parts[0].strip()
    comment_part = parts[1].strip() if len(parts) > 1 else ""

    if not gcode_part:  # Line contains only a comment
        return None, {}, comment_part

    tokens = gcode_part.split()
    command = tokens[0]
    params = {token[0]: float(token[1:]) for token in tokens[1:]}
    return command, params, comment_part

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
    current_position = [0.0, 0.0, SAFE_Z]
    last_probe_position = None
    point_count = 0

    for line in input_stream:
        line = line.strip()
        # Just pass blank lines through
        if not line:
            output_stream.write(line + '\n')
            continue

        # Parse the next GCODE line
        command, params, comment = parse_gcode_line(line)

        # Line contains only a comment, pass it through
        if command is None:
            output_stream.write(f"; {comment}\n")
            continue

        if command == "G1":
            # Ah, a G1 movement. We're interested in those. Where are we going?
            new_position = [
                params.get("X", current_position[0]),
                params.get("Y", current_position[1]),
                params.get("Z", current_position[2])
            ]

            # Only modify the command if we're close to the work surface.
            if new_position[2] < SAFE_Z:
                segments = segment_path(current_position, new_position, SEGMENT_LENGTH)

                # Flag indicating we are definitely at safe height, to raise probe for first move.
                segment_move_flag = 0
                for segment in segments:
                    # Check if this point is sufficiently far from the last probe point
                    if last_probe_position is None or distance_xy(last_probe_position, new_position) >= SEGMENT_LENGTH / 2:
                      # We have not probed near this point before. Output it.
                      # Move to safe Z height if not there already
                      if segment_move_flag == 0:
                        output_stream.write(f"G1 Z10 F900 ; Moving to safe Z\n")
                        output_stream.write(f"G1 Z{SAFE_Z:.3f} F2400\n")
                      # Move to segment point
                      output_stream.write(f"G1 X{segment[0]:.3f} Y{segment[1]:.3f} ; Moving to segment point\n")
                      # Touch down to original height
                      output_stream.write(f"G1 Z{segment[2]+10:.3f} F2400 ; Touching down to original height\n")
                      output_stream.write(f"G1 Z{segment[2]:.3f} F900\n")
                      output_stream.write(f"G1 Z{segment[2]+10:.3f} F900\n")
                      output_stream.write(f"G1 Z{SAFE_Z:.3f} F2400 ; Returning to safe Z\n")
                      segment_move_flag = 1 # Definitely at a SAFE_Z
                      # Set the last probed position so we don't touch near it again.
                      last_probe_position = current_position

                      # We probed a point. See if we've worn all the ink off and need to dip
                      point_count += 1
                      if point_count >= PROBE_POINT_LIMIT:
                          dip_probe(current_position)
                          # Dipping probe resets the point count and also raises it to SAFE_Z
                          point_count = 0

                current_position = new_position
            else:
                # We're above Safe Z, so just execute the existing GCODE
                current_position = new_position
                output_stream.write(line + (' ; ' + comment if comment else '') + '\n')
        else:
            # This is not a G1 code, so just pass it through.
            output_stream.write(line + (' ; ' + comment if comment else '') + '\n')

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

    input_file = None
    output_file = None

    if len(sys.argv) > 1:
        input_file = sys.argv[1]
        if len(sys.argv) > 2:
            output_file = sys.argv[2]

    if input_file:
        with open(input_file, 'r') as infile, open(output_file, 'w') if output_file else sys.stdout as outfile:
            process_gcode(infile, outfile)
    else:
        process_gcode(sys.stdin, sys.stdout)

if __name__ == "__main__":
    main()
