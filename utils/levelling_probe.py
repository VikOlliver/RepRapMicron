#!/usr/bin/env python3
# reprapmicron_probe_corners.py - Revision 0.02
#
# RepRapMicron safe first-run bed probing utility
# - Forces current position as (0,0,SAFE_Z) without moving
# - Probes corners of an n×n square
# - Supports multiple probe attempts per corner with averaging
# - Reports relative heights and identifies high/low corners
# - Returns to (0,0,SAFE_Z) at end
#
# Units: 1 mm in GCODE = 1 micron in machine space.
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

import serial
import time
import re
import argparse

# ---------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------

parser = argparse.ArgumentParser(
    description="Probe bed corners with optional averaging"
)

parser.add_argument("--port", default="/dev/ttyACM0",
                    help="Serial port for GRBL")

parser.add_argument("--baud", type=int, default=115200,
                    help="Serial baud rate")

parser.add_argument("--size", type=float, default=2000,
                    help="Square size (microns)")

parser.add_argument("--safe-z", type=float, default=100,
                    help="Safe Z height")

parser.add_argument("--feed", type=float, default=1000,
                    help="Probe feedrate")

parser.add_argument("--probes", type=int, default=1,
                    help="Number of probe attempts per corner")

args = parser.parse_args()

PORT = args.port
BAUD = args.baud
N = args.size
SAFE_Z = args.safe_z
PROBE_FEED = args.feed
PROBE_COUNT = max(1, args.probes)

points = {
    "BL": (0, 0),
    "BR": (N, 0),
    "TR": (N, N),
    "TL": (0, N)
}

# ---------------------------------------------------------------------
# Serial setup
# ---------------------------------------------------------------------

ser = serial.Serial(PORT, BAUD, timeout=1)
time.sleep(2)

# flush startup messages
while ser.in_waiting:
    ser.readline()

# unlock GRBL
ser.write(b"$X\n")
time.sleep(0.1)
while ser.in_waiting:
    ser.readline()

# force current position as (0,0,SAFE_Z) without moving
ser.write(f"G10 L20 P1 X0 Y0 Z{SAFE_Z}\n".encode())
time.sleep(0.1)

# ---------------------------------------------------------------------
#   Ensure probe is not already in contact before starting.
# ---------------------------------------------------------------------

def check_probe_not_triggered():
    ser.write(b"G91\n")  # relative mode
    # Do a tiny probe. This will fail instantly with ALARM if it is already contacting
    ser.write(f"G38.2 Z-1 F{PROBE_FEED}\n".encode())
    ser.write(b"G90\n")

    saw_prb = False
    saw_alarm = False

    start_time = time.time()

    while time.time() - start_time < 2:
        if ser.in_waiting:
            line = ser.readline().decode(errors="ignore").strip()

            if "PRB:" in line:
                saw_prb = True

            elif "ALARM:" in line:
                saw_alarm = True

    # Clear alarm state if triggered (which it should be one way or another)
    if saw_alarm:
        ser.write(b"$X\n")
        time.sleep(0.1)
        while ser.in_waiting:
            ser.readline()

    # If we saw a PRB, then a probe happened.
    # A PRB would not execute if the probe were already in contact, because
    # that would instantly cause an ALARM
    if not saw_prb:
        print("\nERROR: Probe is already in contact at start!")
        print("Ensure probe is clear of the surface and try again.\n")

        # retract safely
        ser.write(f"G91\nG0 Z{SAFE_Z}\nG90\n".encode())
        time.sleep(0.2)

        ser.close()
        exit(1)

# ---------------------------------------------------------------------
# Probe function
# ---------------------------------------------------------------------

def probe_once():
    ser.write(b"G91\n")
    ser.write(f"G38.2 Z-6000 F{PROBE_FEED}\n".encode())
    ser.write(b"G90\n")

    z = None
    while z is None:
        if ser.in_waiting:
            line = ser.readline().decode(errors="ignore").strip()
            if "PRB:" in line:
                m = re.search(r'PRB:[^,]+,[^,]+,([^:]+)', line)
                if m:
                    z = float(m.group(1))

    # retract
    ser.write(f"G91\nG0 Z{SAFE_Z}\nG90\n".encode())
    return z


def probe_average():
    results = []
    for i in range(PROBE_COUNT):
        z = probe_once()
        results.append(z)

    avg = sum(results) / len(results)
    span = max(results) - min(results) if len(results) > 1 else 0.0

    return avg, results, span


# ---------------------------------------------------------------------
# Main probing loop
# ---------------------------------------------------------------------

heights = {}

# force current position as (0,0,SAFE_Z) without moving
ser.write(f"G10 L20 P1 X0 Y0 Z{SAFE_Z}\n".encode())
time.sleep(0.1)

# Check probe state in case it is already touching
check_probe_not_triggered()

print(f"\n--- Probing corners ({N}x{N})---\n")

for name, (x, y) in points.items():
    ser.write(f"G0 X{x} Y{y}\n".encode())
    time.sleep(0.1)

    avg, samples, span = probe_average()
    heights[name] = avg

    print(f"{name}: {avg:8.3f} µm  (span {span:.3f})")

# ---------------------------------------------------------------------
# Analysis
# ---------------------------------------------------------------------

avg_height = sum(heights.values()) / 4

print("\n--- Relative height to average ---")
for k, v in heights.items():
    print(f"{k}: {v-avg_height:+8.3f} µm")

high = max(heights, key=heights.get)
low = min(heights, key=heights.get)

print(f"\nHighest corner: {high}")
print(f"Lowest corner : {low}")
print(f"Total variation: {heights[high]-heights[low]:.3f} µm")

# ---------------------------------------------------------------------
# Return to origin
# ---------------------------------------------------------------------

ser.write(f"G0 X0 Y0 Z{SAFE_Z}\n".encode())

print(f"\nReturned to (0,0,{SAFE_Z}) for next run\n")
