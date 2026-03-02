# ZelvakCam

A Raspberry Pi camera streaming system with a password-protected web interface.

## Architecture

```
┌──────────────┐        RTMP         ┌──────────────────────────────┐
│  Raspberry Pi │ ──────────────────> │  DigitalOcean Droplet        │
│  (rpicam-vid  │    port 1935        │                              │
│   + ffmpeg)   │                     │  NGINX (RTMP -> HLS)         │
└──────────────┘                     │    localhost:8081             │
                                      │         │                    │
                                      │         v                    │
                                      │  Flask app (port 8080)       │
                                      │    - Login / auth            │
                                      │    - HLS proxy               │
                                      │    - Web UI                  │
                                      └──────────────────────────────┘
                                                  │
                                                  v
                                           Browser (HLS.js)
```

## Prerequisites

- **Raspberry Pi:** Raspberry Pi with camera module, running Raspberry Pi OS
- **Server:** Ubuntu/Debian droplet (DigitalOcean) with ports 1935 and 8080 open
- **Software:** Python 3, NGINX with RTMP module, FFmpeg

## Quick Start

### 1. Raspberry Pi (camera)

```bash
cd rpi
chmod +x setup.sh
sudo ./setup.sh
```

See [rpi/instructions.md](rpi/instructions.md) for details.

### 2. Hosting Server (DigitalOcean droplet)

```bash
cd hosting
chmod +x setup.sh
./setup.sh
```

Edit `.env` with your actual password and secret key, then configure NGINX and start the server.

See [hosting/instructions.md](hosting/instructions.md) for details.

### 3. Access the Web Interface

Open your browser and go to `http://<SERVER_IP>:8080`.

## Configuration

All hosting configuration is managed via `hosting/.env`:

| Variable | Description | Default |
|---|---|---|
| `ZELVAKCAM_PASSWORD` | Login password | `changeme` |
| `FLASK_SECRET_KEY` | Flask session secret | Random on each restart |
| `SERVER_IP` | Server public IP | `134.122.67.47` |
| `FLASK_PORT` | Flask port | `8080` |

The RPi RTMP URL is configured in `/etc/zelvakcam.conf` on the Pi.
