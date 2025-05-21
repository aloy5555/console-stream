#!/bin/bash

# This script will automatically set up everything: Install Docker, FFmpeg, Node.js, create the website, set up the ESP32, and simulate PS4 controller input.

# Step 1: Update and Install Docker
echo "Installing Docker if not already installed..."
if ! command -v docker &> /dev/null; then
  echo "Docker not found. Installing Docker..."
  sudo apt-get update
  sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
else
  echo "Docker is already installed."
fi

# Step 2: Install Docker Compose (if not already installed)
echo "Installing Docker Compose if not already installed..."
if ! command -v docker-compose &> /dev/null; then
  echo "Docker Compose not found. Installing Docker Compose..."
  sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
else
  echo "Docker Compose is already installed."
fi

# Step 3: Install FFmpeg to handle video capture from the capture card
echo "Installing FFmpeg..."
sudo apt-get install -y ffmpeg

# Step 4: Create project directory for your application
PROJECT_DIR="$HOME/ps5-stream"
echo "Creating project directory at $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Step 5: Initialize Node.js Project and Install Dependencies
echo "Initializing Node.js project..."
npm init -y
npm install express express-basic-auth

# Step 6: Create `server.js` file for the Express server with Video Stream and Controller Input
echo "Creating server.js..."
cat <<EOL > server.js
const express = require('express');
const basicAuth = require('express-basic-auth');
const { spawn } = require('child_process');
const fetch = require('node-fetch');

const app = express();
const port = 3000;

// Basic Auth
app.use(basicAuth({
  users: { 'user': 'password' },
  challenge: true,
}));

// Serve the video stream from the capture card (using FFmpeg)
app.get('/video', (req, res) => {
  const ffmpeg = spawn('ffmpeg', [
    '-f', 'v4l2',
    '-i', '/dev/video0',
    '-f', 'mjpeg',
    '-q:v', '5',
    'http://localhost:8081'
  ]);

  ffmpeg.stdout.pipe(res);

  ffmpeg.on('close', () => {
    console.log('FFmpeg process ended');
  });
});

// Handle incoming controller input data
app.post('/controller-input', express.json(), (req, res) => {
  const input = req.body.input;
  console.log('Received controller input:', input);

  // Send data to ESP32
  fetch('http://esp32.local/input', {  // Replace with ESP32's IP address or mDNS name
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ input: input }),
  })
  .then(response => response.json())
  .then(data => console.log('ESP32 received:', data))
  .catch(error => console.error('Error sending data to ESP32:', error));

  res.json({ status: 'success', received: input });
});

app.listen(port, () => {
  console.log(\`Server is running on http://localhost:\${port}\`);
});
EOL

# Step 7: Create HTML file to handle the controller input and display video
echo "Creating HTML file to handle controller input and video stream..."
cat <<EOL > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PS5 Controller Input & Video Stream</title>
</head>
<body>
    <h1>PS5 Controller Input & Video Stream</h1>
    <video id="videoStream" width="640" height="360" controls autoplay></video>
    <script>
        // Function to update the controller input
        function updateController() {
            const gamepads = navigator.getGamepads();

            if (gamepads) {
                for (let i = 0; i < gamepads.length; i++) {
                    const gamepad = gamepads[i];
                    if (gamepad) {
                        // Check button presses
                        gamepad.buttons.forEach((button, index) => {
                            if (button.pressed) {
                                console.log(\`Button \${index} pressed\`);
                                sendInputToServer(\`Button \${index} pressed\`);
                            }
                        });

                        // Check joystick movements
                        const leftStickX = gamepad.axes[0]; // Left stick X axis
                        const leftStickY = gamepad.axes[1]; // Left stick Y axis

                        if (Math.abs(leftStickX) > 0.1 || Math.abs(leftStickY) > 0.1) {
                            console.log(\`Left Stick X: \${leftStickX}, Left Stick Y: \${leftStickY}\`);
                            sendInputToServer(\`Left Stick X: \${leftStickX}, Left Stick Y: \${leftStickY}\`);
                        }
                    }
                }
            }

            requestAnimationFrame(updateController);
        }

        // Send controller input to the server
        function sendInputToServer(inputData) {
            fetch('/controller-input', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ input: inputData }),
            })
            .then(response => response.json())
            .then(data => console.log('Server received:', data))
            .catch(error => console.error('Error sending data to server:', error));
        }

        // Set up video stream element
        function startVideoStream() {
            const video = document.getElementById('videoStream');
            video.src = "http://localhost:8081"; // Stream from FFmpeg server
        }

        window.addEventListener('gamepadconnected', () => {
            console.log('Controller connected');
            updateController();
        });

        // Start video stream when the page loads
        window.onload = startVideoStream;
    </script>
</body>
</html>
EOL

# Step 8: Create Dockerfile to containerize the application
echo "Creating Dockerfile..."
cat <<EOL > Dockerfile
# Use Node.js official image
FROM node:16

# Install FFmpeg in the container
RUN apt-get update && apt-get install -y ffmpeg

# Set working directory inside container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose the necessary ports
EXPOSE 3000
EXPOSE 8081

# Run the app
CMD ["node", "server.js"]
EOL

# Step 9: Create docker-compose.yml file to run the app in a container
echo "Creating docker-compose.yml..."
cat <<EOL > docker-compose.yml
version: '3'

services:
  app:
    build: .
    ports:
      - "3000:3000"
      - "8081:8081"  # Expose port for video stream
    restart: always
EOL

# Step 10: Install ESP32 libraries and program the ESP32
echo "Programming the ESP32..."
cat <<EOL > setup_esp32_controller.ino
#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <ESP32_BLE_Gamepad.h>

// Replace with your network credentials
const char *ssid = "yourSSID";
const char *password = "yourPassword";

// Create an AsyncWebServer object
AsyncWebServer server(80);

// Initialize the gamepad
BLEGamepad bleGamepad;

void setup() {
  Serial.begin(115200);
  
  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Connecting to WiFi...");
  }
  Serial.println("Connected to WiFi");

  // Initialize BLE Gamepad
  BLEDevice::init("ESP32_PS4_Controller");
  BLEServer *pServer = BLEDevice::createServer();
  bleGamepad.begin();

  // Handle HTTP POST requests to simulate button press
  server.on("/input", HTTP_POST, [](AsyncWebServerRequest *request) {
    String input = "";
    if (request->hasParam("input", true)) {
      input = request->getParam("input", true)->value();
    }

    // Simulate button presses or joystick movements based on the input
    if (input == "Button 0 pressed") {
      bleGamepad.press(0);
    } else if (input == "Button 0 released") {
      bleGamepad.release(0);
    }

    // Handle joystick movements
    if (input.startsWith("Left Stick X:")) {
      int xValue = input.substring(14).toInt();
      bleGamepad.setXAxis(xValue);
    }
    if (input.startsWith("Left Stick Y:")) {
      int yValue = input.substring(14).toInt();
      bleGamepad.setYAxis(yValue);
    }

    // Send response back
    request->send(200, "application/json", "{\"status\":\"success\"}");
  });

  // Start the server
  server.begin();
}

void loop() {
  // The loop can stay empty if using HTTP requests for interaction
}
EOL

# Step 11: Build and run Docker container for your web app
echo "Building and running Docker container..."
sudo docker-compose up --build -d

# Step 12: Output the result
echo "Docker container is up and running. You can access your app at http://localhost:3000"
echo "Ensure ESP32 is programmed to send controller input and pair it with PS5 via Bluetooth."
