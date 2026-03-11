#!/usr/bin/python3
"""
RepRapMicron safe first-run bed probing utility
- Forces current position as (0,0,Z_SAFE) without moving
- Probes corners of an n×n square
- Reports relative heights and identifies high/low corners
- Returns to (0,0,Z_SAFE) at end
"""

import serial
import time
import re

PORT = "/dev/ttyACM0"   # replace with your serial port
BAUD = 115200
N = 1000                  # square size in microns
SAFE_Z = 100             # safe Z height above bed
PROBE_FEED = 1000        # probe feedrate in µm/min

points = {
    "BL": (0, 0),
    "BR": (N, 0),
    "TR": (N, N),
    "TL": (0, N)
}

ser = serial.Serial(PORT, BAUD, timeout=1)
time.sleep(2)  # wait for GRBL reset

# flush startup messages
while ser.in_waiting:
    ser.readline()

# unlock GRBL
ser.write(b"$X\n")
time.sleep(0.1)
while ser.in_waiting:
    ser.readline()

# force current position as (0,0,Z_SAFE) without moving
ser.write(f"G10 L20 P1 X0 Y0 Z{SAFE_Z}\n".encode())
time.sleep(0.1)

# function to probe a point
def probe():
    ser.write(b"G91\n")  # relative mode
    ser.write(f"G38.2 Z-6000 F{PROBE_FEED}\n".encode())  # probe down
    ser.write(b"G90\n")  # back to absolute
    z = None
    while z is None:
        if ser.in_waiting:
            line = ser.readline().decode().strip()
            if "PRB:" in line:
                m = re.search(r'PRB:[^,]+,[^,]+,([^:]+)', line)
                z = float(m.group(1))
    # retract to SAFE_Z
    ser.write(f"G91\nG0 Z{SAFE_Z}\nG90\n".encode())
    return z

heights = {}

print("\n--- Probing corners ---")
for name, (x, y) in points.items():
    ser.write(f"G0 X{x} Y{y}\n".encode())
    time.sleep(0.1)
    z = probe()
    heights[name] = z
    print(f"{name}: {z:8.3f} µm")

# report relative heights
avg = sum(heights.values()) / 4
print("\n--- Relative height to average ---")
for k, v in heights.items():
    print(f"{k}: {v-avg:+8.3f} µm")

# identify high and low corners
high = max(heights, key=heights.get)
low = min(heights, key=heights.get)
print(f"\nHighest corner: {high}")
print(f"Lowest corner : {low}")
print(f"Total variation: {heights[high]-heights[low]:.3f} µm")

# move back to (0,0,Z_SAFE)
ser.write(f"G0 X0 Y0 Z{SAFE_Z}\n".encode())
print("\nReturned to (0,0,Z_SAFE) for next run")

