import serial
import serial.tools.list_ports
import re
import json
import sys
import os
import atexit
from flask import Flask, request, jsonify
from threading import Lock

def app_dir():
    if getattr(sys, 'frozen', False):
        return os.path.dirname(sys.executable)
    return os.path.dirname(os.path.abspath(__file__))

BASE_DIR = app_dir()
CONFIG_FILE = os.path.join(BASE_DIR, "serial_config.json")

SERIAL_LOCK = Lock()

app = Flask(__name__)

ser = None
current_config = {}

# ------------------ Utilities ------------------

def list_ports():
    return [p.device for p in serial.tools.list_ports.comports()]

def load_last_config():
    try:
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    except:
        return {}

def save_config(cfg):
    with open(CONFIG_FILE, "w") as f:
        json.dump(cfg, f)

def parity_map(val):
    return {"None": "N", "Even": "E", "Odd": "O"}.get(val, "N")

# ------------------ Serial Control ------------------

def open_serial(cfg):
    global ser

    ser = serial.Serial(
        port=cfg["port"],
        baudrate=int(cfg["baudrate"]),
        bytesize=int(cfg["bytesize"]),
        parity=parity_map(cfg["parity"]),
        stopbits=cfg["stopbits"],
        timeout=0.1
    )

def close_serial():
    global ser
    if ser and ser.is_open:
        ser.close()
    ser = None

def reconfigure_if_needed(new_cfg):
    global current_config

    if new_cfg != current_config:
        close_serial()
        open_serial(new_cfg)
        current_config = new_cfg
        save_config(new_cfg)

# ------------------ Startup ------------------

current_config = load_last_config()

if current_config:
    try:
        open_serial(current_config)
    except:
        current_config = {}

@atexit.register
def cleanup():
    close_serial()

# ------------------ Routes ------------------

@app.route("/ports", methods=["GET"])
def ports():
    return jsonify(list_ports())

@app.route("/read", methods=["POST"])
def read_weight():
    global ser

    cfg = request.json

    with SERIAL_LOCK:
        reconfigure_if_needed(cfg)

        if not ser or not ser.is_open:
            return jsonify({"status": "offline", "weight": None})

        if ser.in_waiting > 0:
            raw = ser.readline()
            line = raw.decode("cp1252", errors="ignore").strip()

            if line:
                # FILTER 1: digits only
                clean_val = re.sub(r"[^0-9]", "", line)

                # FILTER 2: length guard
                if clean_val and 1 < len(clean_val) < 9:
                    try:
                        val = float(clean_val) / 100.0
                        formatted = "{:,.2f}".format(val)
                        return jsonify({
                            "status": "ok",
                            "weight": formatted
                        })
                    except ValueError:
                        pass

        return jsonify({"status": "ok", "weight": None})

# ------------------ Run ------------------

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5050)
