#!/bin/bash

# This script will set up Docker, install dependencies, and create all necessary files to handle PS5 controller input.

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

# Step 3: Get user input for username and password
echo "Please enter the username for basic authentication:"
read USER_NAME

echo "Please enter the password for basic authentication:"
read -s PASSWORD

# Step 4: Create project directory
PROJECT_DIR="$HOME/ps5-stream"
echo "Creating project directory at $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Step 5: Initialize Node.js Project and Install Dependencies
echo "Initializing Node.js project..."
npm init -y
npm install express express-basic-auth

# Step 6: Create `server.js` file for the Express server
echo "Creating server.js..."
cat <<EOL > server.js
const express = require('express');
const basicAuth = require('express-basic-auth');

const app = express();
const port = 3000;

// Basic Auth
app.use(basicAuth({
  users: { '$USER_NAME': '$PASSWORD' },
  challenge: true,
}));

// Serve the video stream or other functionality here
app.get('/', (req, res) => {
  res.send('PS5 Stream will be here!');
});

// Handle incoming controller input data
app.post('/controller-input', (req, res) => {
  const input = req.body.input;
  console.log('Received controller input:', input);

  // Process the input here (e.g., use it for streaming control, game actions, etc.)
  
  res.json({ status: 'success', received: input });
});

app.listen(port, () => {
  console.log(\`Server is running on http://localhost:\${port}\`);
});
EOL

# Step 7: Create HTML file to handle the controller input (Gamepad API)
echo "Creating HTML file to handle controller input..."
cat <<EOL > index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PS5 Controller Input</title>
</head>
<body>
    <h1>PS5 Controller Input</h1>
    <p>Press buttons on your controller!</p>
    <script>
        // Function to check the controller input
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

        window.addEventListener('gamepadconnected', () => {
            console.log('Controller connected');
            updateController();
        });
    </script>
</body>
</html>
EOL

# Step 8: Create Dockerfile to containerize the application
echo "Creating Dockerfile..."
cat <<EOL > Dockerfile
# Use Node.js official image
FROM node:16

# Set working directory inside container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose the port the app will run on
EXPOSE 3000

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
    environment:
      - USER_NAME=$USER_NAME
      - PASSWORD=$PASSWORD
    restart: always
EOL

# Step 10: Build and run Docker container
echo "Building and running Docker container..."
sudo docker-compose up --build -d

# Step 11: Output the result
echo "Docker container is up and running. You can access your app at http://localhost:3000"
