# deltacontrol.py - Prototyping control panel for driving a micro delta stage that uses GRBL
# Released under GPL3 or later by vik@diamondage.co.nz 2024
# Uses the free Zelle portable graphics library
import serial
import serial.tools.list_ports
import time
import math
import numpy as np
from graphics import *

# Define the parameters of the delta platform
stage_radius = 35  # mm (radius of the equilateral triangle around TCP)
stage_height = 70  # 75mm TCP's height above the base. Well default TCP is (0,0,0) so technically the base is below etc.
lever_length = 35   # distance from hinge to pivot.
arm_length = math.sqrt(lever_length**2+stage_height**2) # Distance from driven pivot to stage
base_radius = 35    # mm (base radius, happens to be the same on OpenFlexure Delta)

# Units by which manual controls on the panel move.
step_size = 0.1


def initialize_serial_with_retry(baudrate, suggested_port=None):
    if suggested_port:
        try:
            ser = serial.Serial(suggested_port, baudrate)
            return ser
        except serial.SerialException:
            pass

    while True:
        # Get available serial ports
        available_ports = serial.tools.list_ports.comports()
        port_names = [port.device for port in available_ports]

        # Create a window to select serial port
        serial_win = GraphWin("Select Serial Port", 300, 200)
        serial_win.setCoords(0, 0, 3, len(port_names) + 1)

        # Display available ports
        port_texts = []
        for i, port_name in enumerate(port_names):
            port_texts.append(Text(Point(1, len(port_names) - i), port_name))
            port_texts[-1].draw(serial_win)

        # Allow user to select a port
        while True:
            click_point = serial_win.checkMouse()
            if click_point:
                for i, port_text in enumerate(port_texts):
                    if (port_text.getAnchor().getY() - 0.5) < click_point.getY() < (port_text.getAnchor().getY() + 0.5):
                        selected_port = port_names[i]
                        serial_win.close()
                        break
                else:
                    continue
                break

        # Attempt to initialize serial port
        try:
            ser = serial.Serial(selected_port, baudrate)
            return ser
        except serial.SerialException:
            # Notify user and retry
            error_text = Text(Point(1.5, 0.5), "Failed to initialize serial port.")
            error_text.draw(serial_win)
            time.sleep(2)
            error_text.undraw()

            # Close serial window before retrying
            serial_win.close()

# Open the default port. Put there so it's all in one place.
def open_port():
    return initialize_serial_with_retry(115200,'/dev/ttyACM1')

def send_command(ser, command):
    ser.write(command.encode('ascii'))
    time.sleep(0.1)  # Adjust delay as needed

def receive_response(ser):
    ser.timeout = 10
    response = ser.readline().decode('ascii').strip()
    return response

def wait_for_ok_response(ser):
    while True:
        response = receive_response(ser)
        print("Wait for OK", response)
        if response == "ok":
            break

def wait_show_response(ser):
    start_time = time.time()
    while True:
        if ser.in_waiting > 0:
          response = receive_response(ser)
          print(": ", response)
          start_time = time.time()

        # Wait until no data has been received for a bit
        # This lets the initialisation data scroll past
        time.sleep(0.1)
        if time.time() - start_time >= 2:
          break


# Calculate the angles for each corner of the equilateral triangle given
# a central xyz coordinate
def calculate_triangle_points(coordinate,radius):
    angles = [0, 2 * math.pi / 3, 4 * math.pi / 3]

    # Calculate the coordinates of T[ABC]
    triangle_points = []
    for angle in angles:
        x = coordinate[0] + radius * math.cos(angle)
        y = coordinate[1] + radius * math.sin(angle)
        z = coordinate[2]
        triangle_points.append((x, y, z))

    return tuple(triangle_points)

# Duplicated code, can't be arsed to sort it right now.
def calculate_base_points():
    # Calculate the angles for each corner of the equilateral triangle
    angles = [0, 2 * math.pi / 3, 4 * math.pi / 3]

    # Calculate the coordinates of B[ABC]
    base_points = []
    for angle in angles:
        x = base_radius * math.cos(angle)
        y = base_radius * math.sin(angle)
        z = -stage_height
        base_points.append((x, y, z))

    return tuple(base_points)

# Calculate the distances between corresponding points of the TCP platform and the base.
# Args:
#   - T_ABC (tuple): Tuple containing the coordinates of points on the TCP platform.
#   - B_ABC (tuple): Tuple containing the coordinates of points on the base.
# Returns:
#  - tuple: Tuple containing the distances between corresponding points.
def calculate_distances(T_ABC, B_ABC):

    # Calculate the distances between corresponding points
    distances = []
    for t_point, b_point in zip(T_ABC, B_ABC):
        distance=math.sqrt((t_point[0] - b_point[0])**2 + (t_point[1] - b_point[1])**2 + (t_point[2] - b_point[2])**2)
        distances.append(distance)
    return tuple(distances)

# Knowing the distance between the base hinge and the TCP hinge, we know one side
# of a triangle. The other two sides are the lever length and the stage height.
# Given the height (z) of the TCP is a known constraint, we can calculate the displacement
# of the stage/lever on the Z axis.
#
# l         Distance from base pivot to TCP pivot
# d_tx      Distance in XY plane between base pivot and TCP pivot
# tcp_coord Coordinates of TCP pivot
# base_coord Coordinates of the base pivot.
def lever_displacement(l, d_tx, tcp_coord,base_coord):
    # Calculate the "alpha" angle at vertex A - the base pivot - using the Law of Cosines
    # Top half of Law of Cosines
    upper=(l**2 + lever_length**2 - arm_length**2)
    # Bottom half
    lower=(2 * l * lever_length)
    # Do the division now I've debugged it...
    # Note: Returns value in *radians*
    alpha = math.acos(upper / lower)
    # Now we know what the angle of the hinged joint should be, we can add that
    # to the angle between the Z axis and the TCP. We can use trig to calculate
    # the angle to the Z axis, and add that to the angle between l and lever.
    # Use the remaining pivot angle to calculate the displacement needed at the bottom of
    # the arm. Whew!
    # Note that the TCP when at (0,0,0) is located stage_height above the base, so we add that on.
    theta=alpha+math.atan(d_tx/(tcp_coord[2]+stage_height))
    return lever_length*math.cos(theta)
    


# Process all three of the stage arms in one function.
def calculate_displacements(T_ABC, B_ABC, L_ABC):
    # Initialize an empty list to store the displacements
    D_ABC = []
    
    # Iterate over the TCP coordinates and corresponding L values
    for tcp_coord, base_coord, l_value in zip(T_ABC, B_ABC, L_ABC):
        # Calculate distance in XY plane,TCP pivot minus base pivot
        # Subtract distance from origin, so this can be -ve
        d_tx=math.sqrt(tcp_coord[0]**2+tcp_coord[1]**2)-math.sqrt(base_coord[0]**2+base_coord[1]**2)
        # Calculate the displacement of point c along the z-axis using lever_displacement function
        displacement_c = lever_displacement(l_value, d_tx, tcp_coord, base_coord)
        
        # Append the displacement to the list D_ABC
        D_ABC.append(displacement_c)
    
    return D_ABC


# Function to Calculate Tower Joint Positions:
# - calculate_tower_joint_positions calculates the displacements needed for the bottoms of the arms based
#   on the given TCP location.
# - It utilizes inverse kinematics to determine the distance needed between the TCP joints and the base joints,
#   then shortens the lever arms by bending them.
# - The function takes a TCP location tuple (x, y, z) as input and returns a list of arm displacements.
def calculate_tower_joint_positions(tcp_location):
    # Calculate where the base joints are TBA this should only be called once on initialization.
    B_ABC = calculate_base_points()
    # Calculate the positions of the joints around the TCP stage   
    T_ABC = calculate_triangle_points(tcp_location,stage_radius)
    # Calculate the distance from the TCP to each tower base
    L_ABC=calculate_distances(T_ABC,B_ABC)
    print("Distances: ",L_ABC)
    # Finally, calculate the displacement needed at the bottom of the arms to achieve that distance.
    D_ABC=calculate_displacements(T_ABC, B_ABC, L_ABC);
    print("Displacements: ",D_ABC)
    return D_ABC

# Move the print head to these coordinates, using whatever method
def move_to(location):
  x, y, z = location
  # Format GRBL G0 command
  GRBL_command = f"G0 X{x:.5f} Y{y:.5f} Z{z:.5f}\n"
  print(GRBL_command, end="")
  ser.write(GRBL_command.encode())
  

def draw_axis_location(win, x, y, z):
    # Clear previous axis location text
    if hasattr(win, 'axis_text'):
        win.axis_text.undraw()
    # Draw current axis location text
    axis_location_text = f"Step: {step_size:.4f}    X: {x:.4f}, Y: {y:.4f}, Z: {z:.4f}"
    win.axis_text = Text(Point(win.getWidth() - 180, 20),axis_location_text)
    win.axis_text.draw(win)

def is_clicked(point, button):
    return button.getP1().getX() < point.getX() < button.getP2().getX() and \
           button.getP1().getY() < point.getY() < button.getP2().getY()

if __name__ == "__main__":
    # Initialize serial port
    ser = open_port();
    # Display incoming characters
    print("Starting...")
    wait_show_response(ser)

    # Issue GRBL G92 command to set the current work axes to (0,0,0)
    # This assumes the machine *was* zeroed, which is an iffy thing to do.
    GRBL_command = "G92 X0 Y0 Z0\n"
    print(GRBL_command, end="")
    ser.write(GRBL_command.encode())
    wait_show_response(ser)


    # Initialize axis positions
    x_position, y_position, z_position = 0, 0, 0
    # Find out where the virtual towers are when the TCP is at (0,0,0)
    # This is subtraced from any positioning so movement is relative to (0,0,0)
    tower_zero_offset=calculate_tower_joint_positions((0,0,0))
    print("Tower zero offset: ",tower_zero_offset)


    # Initialize window
    win = GraphWin("Probe Control", 600, 300)
    
   
    # Draw control buttons
    up_button = Rectangle(Point(150, 30), Point(250, 70))
    up_button.draw(win)
    up_text = Text(Point(200, 50), "Up (Y+)")
    up_text.draw(win)
    
    down_button = Rectangle(Point(150, 100), Point(250, 140))
    down_button.draw(win)
    down_text = Text(Point(200, 120), "Down (Y-)")
    down_text.draw(win)
    
    left_button = Rectangle(Point(40, 65), Point(140, 105))
    left_button.draw(win)
    left_text = Text(Point(90, 85), "Left (X-)")
    left_text.draw(win)
    
    right_button = Rectangle(Point(260, 65), Point(360, 105))
    right_button.draw(win)
    right_text = Text(Point(310, 85), "Right (X+)")
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
    while True:
        x_last=x_position
        y_last=y_position
        z_last=z_position
        # Status update can be forced
        update_status=False
        click_point = win.checkMouse()
        if click_point:
            if is_clicked(click_point, up_button):
                y_position += step_size
            elif is_clicked(click_point, down_button):
                y_position -= step_size
            elif is_clicked(click_point, left_button):
                x_position -= step_size
            elif is_clicked(click_point, right_button):
                x_position += step_size
            elif is_clicked(click_point, pageup_button):
                z_position += step_size
            elif is_clicked(click_point, pagedown_button):
                z_position -= step_size
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
            elif is_clicked(click_point, unlock_button):
                # Unlock the CNC driver from fault state. DANGER DANGER!
                GRBL_command = "$X\n"
                print(GRBL_command, end="")
                ser.write(GRBL_command.encode())
                wait_show_response(ser)
                # Set current position as workplace zero coordinates.
                GRBL_command = "G92 X0 Y0 Z0\n"
                print(GRBL_command, end="")
                ser.write(GRBL_command.encode())
                wait_for_ok_response(ser)
                # Display the machine position and error state on text window
                GRBL_command = "?\n"
                ser.write(GRBL_command.encode())
                wait_show_response(ser)
            elif is_clicked(click_point, rehome_button):
                # Seek and rehome the CNC driver, move up a bit, and set zero
                message_win = GraphWin("Message", 300, 100)
                message_text = Text(Point(150, 50), "Homing in progress. Please wait.")
                message_text.draw(message_win)
                # Update the window to finish drawing because we'll be busy...
                message_win.update()
                # Issue GRBL home axes command and wait for the OK
                GRBL_command = "$H\n"
                print(GRBL_command, end="")
                ser.write(GRBL_command.encode())
                wait_for_ok_response(ser)
                # Set current position as workplace zero coordinates
                # before we move up for elbow room.
                GRBL_command = "G92 X0 Y0 Z0\n"
                print(GRBL_command, end="")
                ser.write(GRBL_command.encode())
                wait_for_ok_response(ser)
                # Move up a bit on the Z axis to give arms room to manoeuvre
                GRBL_command = "G0 X2 Y2 Z2\n"
                print(GRBL_command, end="")
                ser.write(GRBL_command.encode())
                wait_for_ok_response(ser)
                # Set current position as workplace zero coordinates.
                GRBL_command = "G92 X0 Y0 Z0\n"
                print(GRBL_command, end="")
                ser.write(GRBL_command.encode())
                wait_for_ok_response(ser)
                message_win.close()
                ## Display on the console what the CNC thinks it is doing
                GRBL_command = "?\n"
                ser.write(GRBL_command.encode())
                wait_show_response(ser)
            elif is_clicked(click_point, stop_button):
                # Close the serial port and open it. This resets the Arduino
                ser.close()
                print("Stopping serial port");
                ser=open_port()
            elif is_clicked(click_point, quit_button):
               break

        # Handling keyboard events
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
            # Finally, check for "Q" to quit
            elif key == "q":
                break

        # If an axis moved, reposition the TCP
        if x_last != x_position or y_last != y_position or z_last != z_position:
            # Figure out the new XYZ for the tower positions
            # Note: Y is inverted in this hardware, so we flip it.
            tower_new_position=calculate_tower_joint_positions((x_position, -y_position, z_position))
            # Subtract the zero offset from each axis. This should not do anything.
            # However, I have misconfigured things before and it has saved my bacon.
            shifted_tower_position=(tower_new_position[0]-tower_zero_offset[0], tower_new_position[1]-tower_zero_offset[1], tower_new_position[2]-tower_zero_offset[2])
            # Now we do the horrible fudging to correct the flaws in my algorithm.
            move_to(shifted_tower_position)
            update_status=True

        if update_status:
            draw_axis_location(win, x_position, y_position, z_position)


    # Close window
    win.close()
