# ZelvakCam RPi Setup Instructions

## Setup

1. Run `chmod +x setup.sh`
2. Run `sudo ./setup.sh` to:
   - Create the `zelvakcam` system user (with `video` group for camera access)
   - Grant the `zelvakcam` user traverse (`o+x`) permission on the project directory path
   - Create `/etc/zelvakcam.conf` with the default RTMP URL
   - Generate the systemd service file with correct paths
   - Install and start the streaming service

## Configuration

The RTMP target URL is configured in `/etc/zelvakcam.conf`:

```
RTMP_URL=rtmp://134.122.67.47/live/stream
```

Edit this file to change the server address, then restart the service.

## Service Management

- Check status: `sudo systemctl status pi-stream.service`
- Stop streaming: `sudo systemctl stop pi-stream.service`
- Start streaming: `sudo systemctl start pi-stream.service`
- Restart: `sudo systemctl restart pi-stream.service`
- Disable autostart: `sudo systemctl disable pi-stream.service`
