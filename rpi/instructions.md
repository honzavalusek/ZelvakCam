# ZelvakCam RPi Setup

1. Run `hosting/setup.sh` on the server first; it prints the `RTMP_URL`.
2. On the Pi: `sudo ./setup.sh` and paste the URL when asked.

This installs `/usr/local/bin/zelvakcam-stream`, the `pi-stream` systemd unit and `/etc/zelvakcam.conf`.

## Configuration (`/etc/zelvakcam.conf`)

| Variable | Default | Notes |
|---|---|---|
| `RTMP_URL` | – | `rtmp://SERVER_IP/cam?user=pi&pass=PUBLISH_KEY` |
| `WIDTH` / `HEIGHT` | 1280 / 720 | |
| `FPS` | 30 | also sets keyframe interval (1 s) |
| `BITRATE` | 2500000 | bits/s |

Restart after editing: `sudo systemctl restart pi-stream`.

## Management

- Status: `systemctl status pi-stream`
- Logs: `journalctl -u pi-stream -f`
- The service retries every 5 s forever, so it recovers when the server comes back.
