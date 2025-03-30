#!/bin/bash

# Make scripts executable
chmod +x stream.sh

# Copy service file to systemd directory
sudo cp pi-stream.service /etc/systemd/system/

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable service to start at boot
sudo systemctl enable pi-stream.service

# Start the service
sudo systemctl start pi-stream.service

echo "ZelvakCam streaming service has been set up and started."
