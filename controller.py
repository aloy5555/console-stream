import requests
import time
from inputs import get_gamepad

PICO_IP = '192.168.1.100'   # <-- Will be patched by the .bat script
CONSOLE_MODE = 'switch'     # 'switch', 'ps4', or 'ps5'; Will be patched by the .bat script

# Button and axis mappings for each mode
MAPPINGS = {
    'switch': {
        'BUTTON_MAP': {
            'BTN_SOUTH': 0,  # A
            'BTN_EAST': 1,   # B
            'BTN_NORTH': 2,  # X
            'BTN_WEST': 3,   # Y
            'BTN_TL': 4,     # L
            'BTN_TR': 5,     # R
            'BTN_SELECT': 8, # Minus
            'BTN_START': 9,  # Plus
            'BTN_THUMBL': 10,# L Stick
            'BTN_THUMBR': 11,# R Stick
            'DPAD_UP': 12,
            'DPAD_DOWN': 13,
            'DPAD_LEFT': 14,
            'DPAD_RIGHT': 15,
            'BTN_MODE': 16,  # Home
        },
        'AXES': 6
    },
    'ps4': {
        'BUTTON_MAP': {
            'BTN_SOUTH': 1,    # Cross
            'BTN_EAST': 2,     # Circle
            'BTN_NORTH': 3,    # Triangle
            'BTN_WEST': 0,     # Square
            'BTN_TL': 4,       # L1
            'BTN_TR': 5,       # R1
            'BTN_SELECT': 8,   # Share
            'BTN_START': 9,    # Options
            'BTN_THUMBL': 10,  # L3
            'BTN_THUMBR': 11,  # R3
            'DPAD_UP': 12,
            'DPAD_DOWN': 13,
            'DPAD_LEFT': 14,
            'DPAD_RIGHT': 15,
            'BTN_MODE': 16,    # PS Button
            'BTN_TOUCH': 17,   # Touchpad Press
        },
        'AXES': 6
    },
    'ps5': {
        'BUTTON_MAP': {
            'BTN_SOUTH': 1,    # Cross
            'BTN_EAST': 2,     # Circle
            'BTN_NORTH': 3,    # Triangle
            'BTN_WEST': 0,     # Square
            'BTN_TL': 4,       # L1
            'BTN_TR': 5,       # R1
            'BTN_SELECT': 8,   # Create
            'BTN_START': 9,    # Options
            'BTN_THUMBL': 10,  # L3
            'BTN_THUMBR': 11,  # R3
            'DPAD_UP': 12,
            'DPAD_DOWN': 13,
            'DPAD_LEFT': 14,
            'DPAD_RIGHT': 15,
            'BTN_MODE': 16,    # PS Button
            'BTN_TOUCH': 17,   # Touchpad Press
            'BTN_MIC': 18,     # Mic Button (if mapped)
        },
        'AXES': 6
    }
}

BUTTON_MAP = MAPPINGS[CONSOLE_MODE]['BUTTON_MAP']
AXES_NUM = MAPPINGS[CONSOLE_MODE]['AXES']

button_state = [0] * (max(BUTTON_MAP.values()) + 1)
axes_state = [128] * AXES_NUM

def normalize_axis(value, deadzone=8000):
    if abs(value) < deadzone:
        return 128
    return int((value + 32768) * 255 / 65535)

def send_state():
    url = f"http://{PICO_IP}/api/gamepad"
    payload = {
        "buttons": button_state,
        "axes": axes_state
    }
    try:
        requests.post(url, json=payload, timeout=0.05)
    except requests.RequestException:
        pass

print(f"Sending controller input to {PICO_IP} emulating {CONSOLE_MODE} (CTRL+C to quit)")

while True:
    events = get_gamepad()
    send_needed = False
    for event in events:
        if event.ev_type == "Key" and event.code in BUTTON_MAP:
            idx = BUTTON_MAP[event.code]
            button_state[idx] = 1 if event.state else 0
            send_needed = True
        if event.ev_type == "Absolute":
            # DPAD
            if event.code == "ABS_HAT0Y":
                # Up/Down
                if 'DPAD_UP' in BUTTON_MAP:
                    button_state[BUTTON_MAP['DPAD_UP']] = 1 if event.state == -1 else 0
                if 'DPAD_DOWN' in BUTTON_MAP:
                    button_state[BUTTON_MAP['DPAD_DOWN']] = 1 if event.state == 1 else 0
                send_needed = True
            if event.code == "ABS_HAT0X":
                if 'DPAD_LEFT' in BUTTON_MAP:
                    button_state[BUTTON_MAP['DPAD_LEFT']] = 1 if event.state == -1 else 0
                if 'DPAD_RIGHT' in BUTTON_MAP:
                    button_state[BUTTON_MAP['DPAD_RIGHT']] = 1 if event.state == 1 else 0
                send_needed = True
            # Sticks and triggers
            if event.code == "ABS_X":
                axes_state[0] = normalize_axis(event.state)
                send_needed = True
            if event.code == "ABS_Y":
                axes_state[1] = normalize_axis(event.state)
                send_needed = True
            if event.code == "ABS_RX":
                axes_state[2] = normalize_axis(event.state)
                send_needed = True
            if event.code == "ABS_RY":
                axes_state[3] = normalize_axis(event.state)
                send_needed = True
            if event.code == "ABS_Z" and AXES_NUM > 4:
                axes_state[4] = int(event.state * 255 / 255) if event.state > 0 else 0
                send_needed = True
            if event.code == "ABS_RZ" and AXES_NUM > 5:
                axes_state[5] = int(event.state * 255 / 255) if event.state > 0 else 0
                send_needed = True
    if send_needed:
        send_state()
    time.sleep(0.01)
