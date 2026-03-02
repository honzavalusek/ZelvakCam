#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Create zelvakcam user if it doesn't exist
if ! id -u zelvakcam &>/dev/null; then
    sudo useradd -r -s /usr/sbin/nologin -G video zelvakcam
    echo "Created zelvakcam user."
fi

# Create default config file if it doesn't exist
if [ ! -f /etc/zelvakcam.conf ]; then
    echo 'RTMP_URL=rtmp://134.122.67.47/live/stream' | sudo tee /etc/zelvakcam.conf > /dev/null
    echo "Created /etc/zelvakcam.conf — edit it to change the RTMP URL."
fi

# Ensure zelvakcam user can traverse the directory path
CURRENT="$SCRIPT_DIR"
while [ "$CURRENT" != "/" ]; do
    sudo chmod o+x "$CURRENT"
    CURRENT="$(dirname "$CURRENT")"
done

# Make scripts executable
chmod +x "$SCRIPT_DIR/stream.sh"

# Generate service file from template with correct paths
sed "s|__INSTALL_DIR__|${SCRIPT_DIR}|g" "$SCRIPT_DIR/pi-stream.service.template" | sudo tee /etc/systemd/system/pi-stream.service > /dev/null

# Reload systemd daemon
sudo systemctl daemon-reload

# Enable service to start at boot
sudo systemctl enable pi-stream.service

# Start the service
sudo systemctl start pi-stream.service

echo "ZelvakCam streaming service has been set up and started."
