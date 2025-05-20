#!/bin/bash

# This script will set up the environment, install dependencies, and run the application in Docker.

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

# Step 3: Create project directory
PROJECT_DIR="$HOME/ps5-stream"
echo "Creating project directory at $PROJECT_DIR"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# Step 4: Initialize Node.js Project and Install Dependencies
echo "Initializing Node.js project..."
npm init -y
npm install express express-basic-auth

# Step 5: Create `server.js` file for the Express server
echo "Creating server.js..."
cat <<EOL > server.js
const express = require('express');
const basicAuth = require('express-basic-auth');

const app = express();
const port = 3000;

// Basic Auth
app.use(basicAuth({
  users: { '\$USER_NAME': '\$PASSWORD' },
  challenge: true,
}));

// Serve your video stream (placeholder for actual stream logic)
app.get('/', (req, res) => {
  res.send('PS5 Stream will be here!');
});

app.listen(port, () => {
  console.log(\`Server is running on http://localhost:\${port}\`);
});
EOL

# Step 6: Create Dockerfile
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

# Step 7: Create docker-compose.yml file to run the app in a container
echo "Creating docker-compose.yml..."
cat <<EOL > docker-compose.yml
version: '3'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - USER_NAME=admin
      - PASSWORD=admin
    restart: always
EOL

# Step 8: Build and run Docker container
echo "Building and running Docker container..."
sudo docker-compose up --build -d

# Step 9: Output the result
echo "Docker container is up and running. You can access your app at http://localhost:3000"

