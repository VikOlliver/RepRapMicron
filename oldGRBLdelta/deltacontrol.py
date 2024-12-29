# deltacontrol.py - Prototyping control panel for driving a micro delta stage that uses GRBL
# Released under GPL3 or later by vik@diamondage.co.nz 2024
# Uses the free Zelle portable graphics library, which requires TkInter
import time
import math
import numpy as np
import os
import dcserial
from graphics import *
# This bit contains the stage configuration if you need to fiddle with that
import dcstage

# Nasty Global variables
# ======================
# Units by which manual controls on the panel move.
step_size = 0.1
# Actual start positions of the delta towers. Set im main loop.
# In theory zero, but in practice may be small roundings or plain wrong
tower_zero_offset=(0,0,0)
# Initial axis positions
# These are the numbers the user sees:
x_position, y_position, z_position = 0, 0, 0
# These are the "machine offsets" which hold position when the user redefines an axis to zero.
x_mc_offset, y_mc_offset, z_mc_offset = 0, 0, 0

# Open the default port. Put there so it's all in one place.
def open_port():
    return dcserial.initialize_with_retry(115200,'/dev/ttyACM1')

# Move the TCP to these coordinates using GRBL to move the stage towers
def grbl_move_to(location):
  x, y, z = location
  # Format GRBL G0 command
  GRBL_command = f"G0 X{x:.5f} Y{y:.5f} Z{z:.5f}\n"
  dcserial.send_GRBL_command_ok(ser,GRBL_command)
  
# Move the TCP to (x,y,z) by calculating the new tower positions, and then calling the
# grbl_move_to function to set them.
# Note: [xyz]_mc_offset contains the offsets applied from initial zero when user
# sets an axis position as zero such as when levelling.
def tcp_move_to(pos):
  # Combine the user coordinates with machine coordinates
  # Note: Y is inverted in this hardware, so we flip it.
  offset_xyz=(x_mc_offset+pos[0],y_mc_offset-pos[1],z_mc_offset+pos[2])
  tower_new_position=dcstage.calculate_joint_positions(offset_xyz)
  # Subtract the zero offset from each axis. This should not do anything.
  # However, I have misconfigured things before and it has saved my bacon.
  shifted_tower_position=(tower_new_position[0]-tower_zero_offset[0], tower_new_position[1]-tower_zero_offset[1], tower_new_position[2]-tower_zero_offset[2])
  # Now we move the GRBL axes to put the TCP in the right place
  grbl_move_to(shifted_tower_position)


def draw_axis_location(win, x, y, z):
    # Clear previous axis location text
    if hasattr(win, 'axis_text'):
        win.axis_text.undraw()
    # Draw current axis location text
    axis_location_text = f"Step: {step_size:.4f}    X: {x:.4f}, Y: {y:.4f}, Z: {z:.4f}"
    win.axis_text = Text(Point(win.getWidth() - 180, 20),axis_location_text)
    win.axis_text.draw(win)

# Figures out if the point supplied is inside a specific button
def is_clicked(point, button):
    return button.getP1().getX() < point.getX() < button.getP2().getX() and \
           button.getP1().getY() < point.getY() < button.getP2().getY()


# Replace the variables x, y, and z in a G-code line with provided values.
# Args:
# gcode_line (str): The G-code line containing variables x, y, and z.
# x (float): Value to replace x variable.
# y (float): Value to replace y variable.
# z (float): Value to replace z variable.
# Returns:
# tuple: Tuple containing the modified x, y, and z values.
def replace_xyz_from_gcode(gcode_line, x, y, z):
    # Regular expression pattern to match x, y, and z values
    pattern = r'([XYZ])([-+]?\d*\.?\d+)'
    
    # Find all matches of x, y, and z values in the G-code line
    matches = re.findall(pattern, gcode_line)
    
    # Replace x, y, and z values with provided arguments
    for variable, value in matches:
        value = float(value)
        if variable == 'X':
            x = value
        elif variable == 'Y':
            y = value
        elif variable == 'Z':
            z = value
    
    return x, y, z



# Opens a file dialog for selecting a file from the specified directory.
#
# Args:
# directory (str): The directory to open the file dialog in. Default is the current directory.
#
# Returns:
# str: The path to the selected file, or None if no file is selected.
def get_gcode_file(directory="."):
    # Use tkinter file dialog
    try:
        import tkinter as tk
        from tkinter import filedialog
    except ImportError:
        raise ImportError("Tkinter is required for file dialogs.")

    root = tk.Tk()
    root.withdraw()  # Hide the main window

    # Open file dialog
    file_path = filedialog.askopenfilename(initialdir=directory, title="Select .gcode file", filetypes=[("G-code files", "*.gcode")])

    return file_path

#    # Example usage
#    selected_file = select_gcode_file()
#    if selected_file:
#        print("Selected file:", selected_file)
#    else:
#        print("No file selected.")

#  Reads a specified file line by line and prints lines starting with 'G0', 'G1', or 'G2'.
#
#  Args:
#  file_path (str): The path to the file to be read.
#
#  Returns:
#  None
def print_gcode_lines(file_path):
    try:
        with open(file_path, 'r') as file:
            for line in file:
                # Strip leading and trailing whitespace
                line = line.strip()
                # Check if the line starts with 'G0', 'G1', or 'G2'
                if line.startswith(('G0', 'G1', 'G2')):
                    print(line)
    except FileNotFoundError:
        print("File not found:", file_path)

# Example usage
#file_path = "example.gcode"  # Specify the path to your file
#print("G-code lines:")
#print_gcode_lines(file_path)


# Expects to use global variables
# step_size - size of a movement control step
# tower_zero_offset - Position of tower bases at actual (0,0,0)
if __name__ == "__main__":

    # Initialize serial port
    ser = open_port();
    # Display incoming characters
    print("Starting...")
    dcserial.wait_for_data_pause(ser)

    # Issue GRBL G92 command to set the current work axes to (0,0,0)
    # This assumes the machine *was* zeroed, which is an iffy thing to do.
    dcserial.send_GRBL_command(ser,"G92 X0 Y0 Z0\n")

    # Find out where the virtual towers are when the TCP is at (0,0,0)
    # This is subtraced from any positioning so movement is relative to (0,0,0)
    tower_zero_offset=dcstage.calculate_joint_positions((0,0,0))
    print("Tower zero offset: ",tower_zero_offset)


    # Initialize window
    win = GraphWin("Probe Control V0.01", 600, 300)
    
   
    # Draw control buttons
    xy0_button = Rectangle(Point(540, 30), Point(590, 70))
    xy0_button.draw(win)
    xy0_text = Text(Point(565, 50), "XY=0")
    xy0_text.draw(win)

    z0_button = Rectangle(Point(540, 100), Point(590, 140))
    z0_button.draw(win)
    z0_text = Text(Point(565, 120), "Z=0")
    z0_text.draw(win)


    up_button = Rectangle(Point(150, 30), Point(250, 70))
    up_button.draw(win)
    up_text = Text(Point(200, 50), "Up (Y+)")
    up_text.draw(win)
    
    down_button = Rectangle(Point(150, 120), Point(250, 160))
    down_button.draw(win)
    down_text = Text(Point(200, 140), "Down (Y-)")
    down_text.draw(win)
    
    home_button = Rectangle(Point(150, 80), Point(250, 110))
    home_button.draw(win)
    home_text = Text(Point(200, 98), "HOME")
    home_text.draw(win)

    left_button = Rectangle(Point(40, 75), Point(140, 115))
    left_button.draw(win)
    left_text = Text(Point(90, 95), "Left (X-)")
    left_text.draw(win)
    
    right_button = Rectangle(Point(260, 75), Point(360, 115))
    right_button.draw(win)
    right_text = Text(Point(310, 95), "Right (X+)")
    right_text.draw(win)
    
    pageup_button = Rectangle(Point(375, 30), Point(500, 70))
    pageup_button.draw(win)
    pageup_text = Text(Point(440, 50), "Page Up (Z+)")
    pageup_text.draw(win)
    
    pagedown_button = Rectangle(Point(375, 100), Point(500, 140))
    pagedown_button.draw(win)
    pagedown_text = Text(Point(440, 120), "Page Down (Z-)")
    pagedown_text.draw(win)

    quit_button = Rectangle(Point(220, 170), Point(280, 210))
    quit_button.draw(win)
    quit_text = Text(Point(250, 190), "Q Quit")
    quit_text.draw(win)

    # Create buttons to set step size
    button_width = 45
    button_spacing = 10
    x_start = 350
    y_start = 250

    label = Text(Point(x_start - 25, y_start), "Step:")
    label.draw(win)
    button_05 = Rectangle(Point(x_start, y_start - 25), Point(x_start + button_width, y_start + 25))
    button_05_label = Text(Point(x_start + button_width / 2, y_start), "0.5")
    button_05.draw(win)
    button_05_label.draw(win)

    button_01 = Rectangle(Point(x_start + button_width + button_spacing, y_start - 25), Point(x_start + 2 * button_width + button_spacing, y_start + 25))
    button_01_label = Text(Point(x_start + 3/2 * button_width + button_spacing, y_start), "0.1")
    button_01.draw(win)
    button_01_label.draw(win)

    button_001 = Rectangle(Point(x_start + 2 * (button_width + button_spacing), y_start - 25), Point(x_start + 3 * button_width + 2 * button_spacing, y_start + 25))
    button_001_label = Text(Point(x_start + 5/2 * button_width + 2 * button_spacing, y_start), "0.01")
    button_001.draw(win)
    button_001_label.draw(win)

    button_0001 = Rectangle(Point(x_start + 3 * (button_width + button_spacing), y_start - 25), Point(x_start + 4 * button_width + 3 * button_spacing, y_start + 25))
    button_0001_label = Text(Point(x_start + 7/2 * button_width + 3 * button_spacing, y_start), "0.001")
    button_0001.draw(win)
    button_0001_label.draw(win)

    # Nice green rehome button
    rehome_button = Rectangle(Point(10, 180), Point(110, 220))
    rehome_button.setFill("green")
    rehome_button.draw(win)
    rehome_text = Text(Point(60, 200), "Re-Home")
    rehome_text.setTextColor("white")
    rehome_text.setSize(15)
    rehome_text.draw(win)

    # Big, red stop button
    stop_button = Rectangle(Point(10, 230), Point(110, 280))
    stop_button.setFill("red")
    stop_button.draw(win)
    stop_text = Text(Point(60, 260), "STOP")
    stop_text.setTextColor("white")
    stop_text.setSize(20)
    stop_text.draw(win)

    # Danger yellow unlock button
    unlock_button = Rectangle(Point(120, 230), Point(220, 280))
    unlock_button.setFill("yellow")
    unlock_button.draw(win)
    unlock_text = Text(Point(170, 260), "UNLOCK")
    unlock_text.setTextColor("black")
    unlock_text.setSize(15)
    unlock_text.draw(win)
 

    # Draw initial axis location
    draw_axis_location(win, x_position, y_position, z_position)
    # Main loop for handling user input
    # Some buttons emulate a keypress so we can keep code all in one place
    while True:
        key = ""
        x_last=x_position
        y_last=y_position
        z_last=z_position
        # Status update can be forced
        update_status=False
        click_point = win.checkMouse()
        if click_point:
            if is_clicked(click_point, up_button):
                key = 'Up'
            elif is_clicked(click_point, down_button):
                key = 'Down'
            elif is_clicked(click_point, left_button):
                key = 'Left'
            elif is_clicked(click_point, right_button):
                key = 'Right'
            elif is_clicked(click_point, pageup_button):
                key = 'Prior'
            elif is_clicked(click_point, pagedown_button):
                key = 'Next'
            # These bits set the size of the steps we move the XY or Z axes in
            if is_clicked(click_point, button_05):
                step_size=0.5
                update_status=True
            if is_clicked(click_point, button_01):
                step_size=0.1
                update_status=True
            elif is_clicked(click_point, button_001):
                step_size=0.01
                update_status=True
            elif is_clicked(click_point, button_0001):
                step_size=0.001
                update_status=True
            elif is_clicked(click_point,home_button):
                key = 'Home'
            elif is_clicked(click_point, xy0_button):
                # Set the current point to X=0 Y=0 by adjusting the machine offset, ignore Z
                x_mc_offset+=x_position
                y_mc_offset+=y_position
                update_status=True
                last_x=last_y=x_position=y_position=0
            elif is_clicked(click_point, z0_button):
                # Set the current point to Z=0 by adjusting the machine offset, ignore XY
                z_mc_offset+=z_position
                update_status=True
                last_z=z_position=0
            elif is_clicked(click_point, unlock_button):
                # Unlock the CNC driver from fault state. DANGER DANGER!
                # Because we don't know what will happen, we just wait for data to
                # cease being sent to us by GRBL rather than look for "ok"
                dcserial.send_GRBL_command(ser,"$X\n")
                # Set current position as workplace zero coordinates.
                dcserial.send_GRBL_command_ok(ser,"G92 X0 Y0 Z0\n")
                # Display the machine position and error state on text window
                # Because we don't know what will happen, we just wait for data to
                # cease being sent to us by GRBL rather than look for "ok"
                dcserial.send_GRBL_command(ser,"?\n")
            elif is_clicked(click_point, rehome_button):
                # Seek and rehome the CNC driver, move up a bit, and set zero
                message_win = GraphWin("Message", 300, 100)
                message_text = Text(Point(150, 50), "Homing in progress. Please wait.")
                message_text.draw(message_win)
                # Update the window to finish drawing because we'll be busy...
                message_win.update()
                # Issue GRBL home axes command and wait for the OK
                dcserial.send_GRBL_command_ok(ser,"$H\n")
                # Set current position as workplace zero coordinates
                # before we move up for elbow room.
                dcserial.send_GRBL_command_ok(ser,"G92 X0 Y0 Z0\n")
                # Move up a bit on the Z axis to give arms room to manoeuvre
                dcserial.send_GRBL_command_ok(ser,"G0 X2 Y2 Z2\n")
                # Set current position as workplace zero coordinates.
                dcserial.send_GRBL_command_ok(ser,"G92 X0 Y0 Z0\n")
                message_win.close()
                ## Display on the console what the CNC thinks it is doing
                dcserial.send_GRBL_command(ser,"?\n")
            elif is_clicked(click_point, stop_button):
                # Close the serial port and open it. This resets the Arduino
                ser.close()
                print("Stopping serial port");
                ser=open_port()
            elif is_clicked(click_point, quit_button):
               break

        # Handling keyboard events
        if key == "":
          key = win.checkKey()
        if key:
            if key == 'Up':
                y_position += step_size
            elif key == 'Down':
                y_position -= step_size
            elif key == 'Left':
                x_position -= step_size
            elif key == 'Right':
                x_position += step_size
            elif key == 'Prior':
                z_position += step_size
            elif key == 'Next':
                z_position -= step_size
            elif key == 'Home':
                # Home the XY axes first, then the Z
                # Set xyz so no further movement is made.
                x_position=y_position=0
                print("Move XY to zero")
                tcp_move_to((x_position, y_position, z_position))
                z_position=0
                print("Move Z  to zero")
                tcp_move_to((x_position, y_position, z_position))
                last_x=last_y=Last_z=0
                update_status=True
            # Finally, check for "Q" to quit
            elif key == "q":
                break

        # If an axis moved, reposition the TCP
        if x_last != x_position or y_last != y_position or z_last != z_position:
            # Figure out the new XYZ for the tower positions
            tcp_move_to((x_position, y_position, z_position))
            update_status=True

        if update_status:
            draw_axis_location(win, x_position, y_position, z_position)


    # Close window
    win.close()
