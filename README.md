# ZelvakCam

Raspberry Pi camera → password-protected, low-latency (<1 s) web page.

```
Pi: rpicam-vid | ffmpeg -c copy ──RTMP (publish key)──► droplet :1935
                                                          │
 MediaMTX (RTMP in; WebRTC :8889 / HLS :8888 on localhost only)
                                                          │
 Caddy :443 (auto HTTPS) ──forward_auth──► Flask /auth (login session)
        └─ /webrtc/*, /hls/* → MediaMTX   └─ everything else → Flask (gunicorn)
                                                          │
                                           Browser: WebRTC, HLS fallback
```

The stream can only be played through the web login (MediaMTX allows reads from localhost only) and only published with the secret key.

## Setup

1. Server: `cd hosting && ./setup.sh` (see [hosting/instructions.md](hosting/instructions.md)). Note the printed `RTMP_URL`.
2. Pi: `cd rpi && sudo ./setup.sh` (see [rpi/instructions.md](rpi/instructions.md)).
3. Open the printed `https://<ip>.sslip.io` and log in.

## Configuration

Server: `hosting/.env` (`ZELVAKCAM_PASSWORD`, `FLASK_SECRET_KEY`, `SERVER_IP`, `DOMAIN`, `PUBLISH_KEY`). Pi: `/etc/zelvakcam.conf` (URL, resolution, fps, bitrate).

## Troubleshooting

- "Camera offline": `journalctl -u pi-stream -f` on the Pi, `journalctl -u mediamtx -f` on the server.
- WebRTC fails behind strict networks: the player falls back to HLS automatically (~2–4 s delay).
- Port 80/443 must be reachable for Let's Encrypt certificates.
