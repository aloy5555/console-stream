#!/bin/bash

# This script will automatically detect the video capture card, set up the Docker, and configure everything to handle PS5 controller input and video capture streaming.

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

# Step 4: Detect available capture devices
echo "Detecting video capture devices..."
CAPTURE_DEVICE=""
for device in /dev/video*; do
  if [ -e "$device" ]; then
    CAPTURE_DEVICE=$device
    break
  fi
done

if [ -z "$CAPTURE_DEVICE" ]; then
  echo "No video capture device found. Exiting..."
  exit 1
else
  echo "Found video capture device: $CAPTURE_DEVICE"
fi

# Step 5: Get user input for username and password
echo "Please enter the username for basic authentication:"
read USER_NAME

echo "Please enter the password for basic authentication:"
read -s PASSWORD

# Step 6: Create project directory
PROJECT_DIR="$HOME/ps5-stream"
echo "Creating project directory at $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Step 7: Initialize Node.js Project and Install Dependencies
echo "Initializing Node.js project..."
npm init -y
npm install express express-basic-auth

# Step 8: Create `server.js` file for the Express server with Video Stream and Controller Input
echo "Creating server.js..."
cat <<EOL > server.js
const express = require('express');
const basicAuth = require('express-basic-auth');
const { spawn } = require('child_process');

const app = express();
const port = 3000;

// Basic Auth
app.use(basicAuth({
  users: { '$USER_NAME': '$PASSWORD' },
  challenge: true,
}));

// Serve the video stream from the capture card (using FFmpeg)
app.get('/video', (req, res) => {
  // Stream video from the capture card via FFmpeg
  const ffmpeg = spawn('ffmpeg', [
    '-f', 'v4l2',
    '-i', '$CAPTURE_DEVICE',  # Use the detected capture device
    '-f', 'mjpeg',
    '-q:v', '5',
    'http://localhost:8081'
  ]);

  // Pipe the output to the response stream
  ffmpeg.stdout.pipe(res);

  ffmpeg.on('close', () => {
    console.log('FFmpeg process ended');
  });
});

// Handle incoming controller input data
app.post('/controller-input', express.json(), (req, res) => {
  const input = req.body.input;
  console.log('Received controller input:', input);

  // Process the input here (e.g., use it for streaming control, game actions, etc.)
  
  res.json({ status: 'success', received: input });
});

app.listen(port, () => {
  console.log(\`Server is running on http://localhost:\${port}\`);
});
EOL

# Step 9: Create HTML file to handle the controller input and display video
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

# Step 10: Create Dockerfile to containerize the application
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

# Step 11: Create docker-compose.yml file to run the app in a container
echo "Creating docker-compose.yml..."
cat <<EOL > docker-compose.yml
version: '3'

services:
  app:
    build: .
    ports:
      - "3000:3000"
      - "8081:8081"  # Expose port for video stream
    environment:
      - USER_NAME=$USER_NAME
      - PASSWORD=$PASSWORD
    restart: always
EOL

# Step 12: Build and run Docker container
echo "Building and running Docker container..."
sudo docker-compose up --build -d

# Step 13: Output the result
echo "Docker container is up and running. You can access your app at http://localhost:3000"
