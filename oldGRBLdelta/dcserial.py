# dcserial.py - Serial port routines used by deltacontrol Control Panel
# Released under GPL3 or later by vik@diamondage.co.nz 2024
# Uses the free Zelle portable graphics library

import serial
import serial.tools.list_ports
from graphics import *


def initialize_with_retry(baudrate, suggested_port=None):
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

# Send an ascii string out of the serial port and wait a bit for it to go out.
def send_string(ser, command):
    ser.write(command.encode('ascii'))
    time.sleep(0.1)  # Adjust delay as needed

# Wait for an ascii string to come in the serial port with a timeout of 10s
def receive_string(ser):
    ser.timeout = 10
    response = ser.readline().decode('ascii').strip()
    return response

# Wait forever for an "ok" response from the serial port.
def send_string_wait_ok(ser):
    while True:
        response = receive_string(ser)
        print("Wait for OK", response)
        if response == "ok":
            break

# Wait for serial data to stop coming in for 2 seconds, sending rsponses
# to the console. This is used to absorb initialisation information
# after a controller reset.
def wait_for_data_pause(ser):
    start_time = time.time()
    while True:
        if ser.in_waiting > 0:
          response = receive_string(ser)
          print(": ", response)
          start_time = time.time()

        # Wait until no data has been received for a bit
        # This lets the initialisation data scroll past
        time.sleep(0.1)
        if time.time() - start_time >= 2:
          break

# Sends a command to the GRBL hardware on the serial port.
# Waits a good long time before returning but does not return a
# success code.
def send_GRBL_command(ser,GRBL_command):
    print(GRBL_command, end="")
    ser.write(GRBL_command.encode())
    wait_for_data_pause(ser)

# Sends a GRBL command to the serial port. Waits for an
# "ok" before returning. Will wait indefinitely.
def send_GRBL_command_ok(ser,GRBL_command):
    print(GRBL_command, end="")
    ser.write(GRBL_command.encode())
    send_string_wait_ok(ser)
