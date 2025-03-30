# ZelvakCam Setup Instructions

## Setup
1. Run `chmod +x setup.sh`
2. Run `sudo ./setup.sh` to:
   - Install the streaming service
   - Enable the service to start at boot
   - Start the streaming service

## Service Management
- Check status: `sudo systemctl status pi-stream.service`
- Stop streaming: `sudo systemctl stop pi-stream.service`
- Start streaming: `sudo systemctl start pi-stream.service`
- Disable autostart: `sudo systemctl disable pi-stream.service`
