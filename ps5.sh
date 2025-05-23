#!/bin/bash
set -e

PROJECT_DIR="$HOME/console-stream"
FLASH_DIR="$PROJECT_DIR/flash-project"
NODE_HANDLER="$PROJECT_DIR/controller-handler.js"
PY_VIRTUAL_CONTROLLER="$PROJECT_DIR/virtual_controller.py"
STREAM_SERVER_JS="$PROJECT_DIR/stream-server.js"

echo "🎮 Welcome to the Console Streaming Setup Script!"

install_dependencies() {
  echo "🔧 Installing dependencies..."
  sudo apt-get update
  sudo apt-get install -y docker.io docker-compose ffmpeg nodejs npm python3 python3-pip libevdev-dev libudev-dev curl unzip
  pip3 install --upgrade python-uinput evdev
}

setup_node_project() {
  mkdir -p "$PROJECT_DIR"
  cd "$PROJECT_DIR"
  npm init -y
  npm install express express-basic-auth node-hid serialport
}

create_virtual_controller() {
  cat <<'EOF' > "$PY_VIRTUAL_CONTROLLER"
#!/usr/bin/env python3
import uinput, time

events = (
    uinput.BTN_A, uinput.BTN_B,
    uinput.BTN_X, uinput.BTN_Y,
    uinput.BTN_START, uinput.BTN_SELECT,
    uinput.ABS_X + (-32768, 32767, 0, 0),
    uinput.ABS_Y + (-32768, 32767, 0, 0)
)

device = uinput.Device(events, name="Virtual Gamepad")
print("🎮 Virtual gamepad active. Ctrl+C to stop.")

try:
    while True:
        device.emit(uinput.BTN_A, 1)
        time.sleep(0.1)
        device.emit(uinput.BTN_A, 0)
        time.sleep(2)
except KeyboardInterrupt:
    print("🛑 Virtual gamepad stopped.")
EOF
  chmod +x "$PY_VIRTUAL_CONTROLLER"
}

create_streaming_server() {
  mkdir -p "$PROJECT_DIR/public"

  cat <<'EOF' > "$STREAM_SERVER_JS"
const express = require('express');
const app = express();
const port = 3000;
app.use(express.static(__dirname + '/public'));
app.listen(port, () => {
  console.log(`🎥 Streaming server at http://localhost:${port}`);
});
EOF

  cat <<'EOF' > "$PROJECT_DIR/public/index.html"
<!DOCTYPE html>
<html><head><title>Console Stream</title></head>
<body>
  <h1>📺 Live Stream</h1>
  <video autoplay muted controls id="stream" width="800"></video>
  <script>
    const video = document.getElementById('stream');
    video.src = 'http://localhost:8090/stream';
  </script>
</body></html>
EOF
}

start_local_stream() {
  echo "📺 Starting screen stream on port 8090..."
  ffmpeg -f x11grab -r 30 -s 1280x720 -i :0.0 \
         -vcodec libx264 -preset ultrafast -tune zerolatency \
         -f mpegts http://localhost:8090/stream &
}

generate_ino_file() {
  local console=$1 pin1=$2 pin2=$3
  cat <<EOF > "$PROJECT_DIR/${console}-controller.ino"
#include <Wire.h>
#include <ESP32Servo.h>

#define BUTTON_1 $pin1
#define BUTTON_2 $pin2

void setup() {
  Serial.begin(115200);
  pinMode(BUTTON_1, INPUT_PULLUP);
  pinMode(BUTTON_2, INPUT_PULLUP);
}

void loop() {
  if (digitalRead(BUTTON_1) == LOW) Serial.println("${console^^} Button 1 pressed!");
  if (digitalRead(BUTTON_2) == LOW) Serial.println("${console^^} Button 2 pressed!");
  delay(100);
}
EOF
}

flash_esp32() {
  local ino_file=$1
  if ! command -v arduino-cli &>/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh | sh
    export PATH="$PATH:$HOME/bin"
  fi

  arduino-cli core update-index
  arduino-cli core install esp32:esp32

  local port
  port=$(arduino-cli board list | grep -i "esp32" | awk '{print $1}')
  [ -z "$port" ] && port=$(ls /dev/ttyUSB* 2>/dev/null | head -n 1)

  [ -z "$port" ] && { echo "⚠️ No ESP32 found."; return; }

  mkdir -p "$FLASH_DIR"
  cp "$ino_file" "$FLASH_DIR/sketch.ino"
  cd "$FLASH_DIR"
  arduino-cli compile --fqbn esp32:esp32:esp32 sketch.ino
  arduino-cli upload -p "$port" --fqbn esp32:esp32:esp32 sketch.ino
  echo "✅ ESP32 flashed."
  cd "$PROJECT_DIR"
}

setup_console() {
  local console=$1 pin1=$2 pin2=$3
  setup_node_project
  generate_ino_file "$console" "$pin1" "$pin2"
  flash_esp32 "$PROJECT_DIR/${console}-controller.ino"
}

main_menu() {
  echo ""
  echo "📋 Main Menu:"
  echo "1) Setup for PS5 (ESP32)"
  echo "2) Setup for PS4 (ESP32)"
  echo "3) Setup for Switch (ESP32)"
  echo "5) Setup for PC only (streaming + uinput)"
  echo "6) Exit"
  read -rp "Choose an option: " opt

  case $opt in
    1) setup_console "ps5" 13 12 ;;
    2) setup_console "ps4" 14 15 ;;
    3) setup_console "switch" 16 17 ;;
    5)
      echo "🖥️ Setting up PC-only mode..."
      install_dependencies
      create_virtual_controller
      create_streaming_server
      echo "🔧 Enabling uinput..."
      sudo modprobe uinput
      sudo chmod 666 /dev/uinput
      start_local_stream
      node "$STREAM_SERVER_JS" &
      sleep 2
      xdg-open http://localhost:3000
      "$PY_VIRTUAL_CONTROLLER"
      ;;
    6) echo "👋 Goodbye."; exit 0 ;;
    *) echo "❌ Invalid option";;
  esac

  main_menu
}

install_dependencies
create_virtual_controller
create_streaming_server
main_menu
