# dcstage.py - Calculates geometry for driving a micro delta stage that uses GRBL
# Released under GPL3 or later by vik@diamondage.co.nz 2024

import math

# In the CNC world, the tip is often referred to as the Tool Control Point (TCP)
# The "towers" are the driven axes. GRBL is driving AX BY CZ
#
# Define the parameters of the delta platform
stage_radius = 35  # mm (radius of the equilateral triangle around TCP)
stage_height = 70  # 75mm TCP's height above the base. Well default TCP is (0,0,0) so technically the base is below etc.
lever_length = 35   # distance from hinge to pivot.
arm_length = math.sqrt(lever_length**2+stage_height**2) # Distance from driven pivot to stage
base_radius = 35    # mm (base radius, happens to be the same on OpenFlexure Delta)


# Calculate the points for each centre joint of the equilateral triangle of the
# stage given a central xyz coordinate
def calculate_stage_points(coordinate,radius):
    angles = [0, 2 * math.pi / 3, 4 * math.pi / 3]

    # Calculate the coordinates of T[ABC]
    triangle_points = []
    for angle in angles:
        x = coordinate[0] + radius * math.cos(angle)
        y = coordinate[1] + radius * math.sin(angle)
        z = coordinate[2]
        triangle_points.append((x, y, z))

    return tuple(triangle_points)

# Calculate the position for each centre of the base joints.
# Yes this is a lot of duplicated code, can't be arsed to sort it right now.
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
def calculate_all_levers(T_ABC, B_ABC, L_ABC):
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
# - calculate_joint_positions calculates the displacements needed for the bottoms of the arms based
#   on the given TCP location.
# - It utilizes inverse kinematics to determine the distance needed between the TCP joints and the base joints,
#   then shortens the lever arms by bending them.
# - The function takes a TCP location tuple (x, y, z) as input and returns a list of arm displacements.
def calculate_joint_positions(tcp_location):
    # Calculate where the base joints are TBA this should only be called once on initialization.
    B_ABC = calculate_base_points()
    # Calculate the positions of the joints around the TCP stage   
    T_ABC = calculate_stage_points(tcp_location,stage_radius)
    # Calculate the distance from the TCP to each tower base
    L_ABC=calculate_distances(T_ABC,B_ABC)
    print("Distances: ",L_ABC)
    # Finally, calculate the displacement needed at the bottom of the arms to achieve that distance.
    D_ABC=calculate_all_levers(T_ABC, B_ABC, L_ABC);
    print("Displacements: ",D_ABC)
    return D_ABC
