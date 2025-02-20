"""This contains functions for specific tasks"""
from appclass.file_class import FileHandler
import re
import socket
import json


def save_files_to_app(filepath, location):
    """saves files to the user's app directory"""
    handler = FileHandler(filepath)
    response = handler.save_file(location)
    if response:
        message = 'file saved successfully!'
        status = 1
    else:
        status = 2
        message = 'Operation was not successful.'

    return {'status': status, 'data': None, 'message': message, 'error': None}


def read_app_settings():
    file_path = "app_settings.json"
    try:
        with open(file_path, 'r') as file:
            settings = json.load(file)
        data = settings
        status = 1
        message = "success"
    except FileNotFoundError:
        data = None
        status = 2
        message = f"File '{file_path}' not found."
        print(message)
    except json.JSONDecodeError:
        data = None
        status = 2
        message = f"Error decoding JSON from '{file_path}'. Check if the file contains valid JSON."
        print(message)

    return {'status': status, 'message': message, 'data': data}


def get_unit():
    """extracts unit from settings file"""
    unit = 'Kg'
    settings_data = read_app_settings()
    if settings_data['data'] is not None:
        unit = settings_data['data']['unit']

    return unit


def process_mass(obj) -> dict:
    """processes the mass data in the obj"""
    initial_mass = 0 if not obj.initial_weight else int(obj.initial_weight)
    final_mass = None if not obj.final_weight else int(obj.final_weight)

    mr = {}
    if final_mass:
        # check which is larger
        if initial_mass < final_mass:
            mr['tare_mass'] = f"{initial_mass} {get_unit()}  | {obj.initial_time.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')}"
            mr['gross_mass'] = f"{final_mass} {get_unit()}  | {obj.final_time.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')}"
            mr['net_mass'] = f"{final_mass - initial_mass} {get_unit()}"
        else:
            mr['tare_mass'] = f"{final_mass} {get_unit()}  | {obj.final_time.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')}"
            mr['gross_mass'] = f"{initial_mass} {get_unit()}  | {obj.initial_time.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')}"
            mr['net_mass'] = f"{initial_mass - final_mass} {get_unit()}"
    else:
        mr['tare_mass'] = f"{initial_mass} {get_unit()}  | {obj.initial_time.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')}"
        mr['gross_mass'] = "-"
        mr['net_mass'] = "-"

    return mr


def check_password_strength(password: str) -> dict:
    """validates password for certain criteria """
    error = []
    special = '[@_!#$%^&*()<>?/\|}{~:]'
    if len(password) < 8:
        error.append("Password cannot be less than 8 characters ")
    if re.search('[0-9]', password) is None:
        error.append("Password must include at least one number!")
    if re.search("[a-zA-Z]", password) is None:
        error.append("Password must include at least one letter!")
    if re.search('[A-Z]', password) is None:
        error.append("Password must include at least one UPPERCASE letter!")
    if re.search('[a-z]', password) is None:
        error.append("Password must include at least one LOWERCASE letter!")
    if re.compile(special).search(password) is None:
        error.append("Password must include at least one special character: {}".format(special))
    if len(error) > 0:
        return {'status': 2, "message": "Password Not Ok", 'error': error}
    return {"status": 1, "message": "Password Ok", "error": []}

def get_ip_address():
    """
    Retrieves the local IP address of the system by creating a socket connection
    to a remote server (in this case, Google's DNS server) and extracting the
    local IP address connected to it.

    Returns:
        str: The IP address of the system if retrieved successfully.
             If unable to retrieve the IP address, returns a message indicating
             the failure.
    """
    try:
        # Create a socket object
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # Connect to a remote server (does not send any packets)
        sock.connect(("8.8.8.8", 80))
        # Get the local IP address connected to the remote host
        ip_address = sock.getsockname()[0]
        # Close the socket
        sock.close()
        return ip_address
    except socket.error:
        return "Unable to retrieve IP address"

