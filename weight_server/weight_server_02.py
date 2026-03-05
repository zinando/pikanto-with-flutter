import serial
import serial.tools.list_ports
import re
import json
import sys
import os
import atexit
from flask import Flask, request, jsonify
from threading import Lock
import time

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
    return {"none": "N", "even": "E", "odd": "O", "n": "N", "e": "E", "o": "O"}.get(val, "N")

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

def normalize_config(cfg):
    return {
        "port": str(cfg["port"]),
        "baudrate": int(cfg["baudrate"]),
        "bytesize": int(cfg["bytesize"]),
        "parity": str(cfg["parity"]).strip().lower(),
        "stopbits": int(cfg["stopbits"]),
    }

# ------------------ Routes ------------------

@app.route("/ports", methods=["GET"])
def ports():
    return jsonify(list_ports())

@app.route("/read", methods=["POST"])
def read_weight():
    try:
        global ser

        cfg = request.get_json(silent=True)
        cfg = normalize_config(cfg)
        
        if not cfg:
            raise Exception("Invalid or Missing json payload.")

        with SERIAL_LOCK:
            reconfigure_if_needed(cfg)

            if not ser or not ser.is_open:
                raise Exception("Offline")

            if ser.in_waiting > 0:
                raw = ser.read(ser.in_waiting).decode("cp1252", errors="ignore")
                # regex: finds numbers including decimals
                matches = re.findall(r"[-+]?\d*\.\d+|\d+", raw)
                if matches:
                    # Pick the longest match to avoid status digits (e.g., '0')
                    val = max(matches, key=len)
                    num = float(val)
                    formatted = "{:,.2f}".format(num)
                    return jsonify({
                        "status": "ok",
                        "weight": formatted
                    })
            time.sleep(0.1)
    except Exception as e:
        return jsonify({
            "status": "error",
            "error": str(e)
        }), 400

# ------------------ Run ------------------

if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5050)
