# ESP32 Switch Controller Emulator

This project utilizes an ESP32 microcontroller to emulate a Nintendo Switch controller, enabling wireless gameplay on your Switch using Moonlight.

## Features

- Emulates both Left and Right Joy-Con controllers
- Compatible with Nintendo Switch via Bluetooth
- Customizable button mappings
- Supports battery level reporting

## Setup Instructions

1. Clone this repository to your local machine.
2. Run the `setup.bat` script to install necessary tools and libraries.
3. Open the `Bluepad32.ino` file in the Arduino IDE.
4. Select your ESP32 board and port in the Arduino IDE.
5. Upload the firmware to your ESP32.

## Controller Configuration

- GPIO 3: Stick Button Right / R3
- GPIO 4: Capture
- GPIO 5: X
- GPIO 12: ( - ) / SELECT
- GPIO 13: ( + ) / START
- GPIO 14: Dpad Right
- GPIO 15: Sync
- GPIO 16: Home
- GPIO 17: Y
- GPIO 18: A
- GPIO 19: B
- GPIO 21: Stick Button Left / L3
- GPIO 22: R / R1
- GPIO 23: L / L1
- GPIO 25: Dpad Up
- GPIO 26: Dpad Down
- GPIO 27: Dpad Left
- GPIO 32: ZL / L2
- GPIO 33: ZR / R2
- GPIO 34: Right Stick X Axis
- GPIO 35: Right Stick Y Axis
- GPIO 36: Left Stick X Axis
- GPIO 39: Left Stick Y Axis

## License

This project is licensed under the MIT License.
