#!/bin/bash
# Run on the Raspberry Pi: sudo ./setup.sh
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo"; exit 1; }

DIR="$(cd "$(dirname "$0")" && pwd)"

command -v ffmpeg >/dev/null || { apt-get update; apt-get install -y ffmpeg; }
command -v rpicam-vid >/dev/null || { echo "rpicam-vid not found (install rpicam-apps)"; exit 1; }

id -u zelvakcam &>/dev/null || useradd -r -s /usr/sbin/nologin -G video zelvakcam

install -m 755 "$DIR/stream.sh" /usr/local/bin/zelvakcam-stream
install -m 644 "$DIR/pi-stream.service" /etc/systemd/system/pi-stream.service

if [ ! -f /etc/zelvakcam.conf ]; then
    install -m 640 -o root -g zelvakcam "$DIR/zelvakcam.conf.example" /etc/zelvakcam.conf
    read -rp "RTMP URL (printed by hosting/setup.sh): " URL
    if [ -n "$URL" ]; then
        { printf "RTMP_URL='%s'\n" "$URL"; grep -v '^RTMP_URL=' /etc/zelvakcam.conf; } > /etc/zelvakcam.conf.new
        install -m 640 -o root -g zelvakcam /etc/zelvakcam.conf.new /etc/zelvakcam.conf && rm /etc/zelvakcam.conf.new
    fi
fi

systemctl daemon-reload
systemctl enable pi-stream.service
systemctl restart pi-stream.service
echo "Done. Logs: journalctl -u pi-stream -f"
