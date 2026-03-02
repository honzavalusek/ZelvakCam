#!/bin/bash
set -euo pipefail

# Load config from environment or config file
if [ -f /etc/zelvakcam.conf ]; then
    source /etc/zelvakcam.conf
fi

URL="${RTMP_URL:-rtmp://134.122.67.47/live/stream}"

rpicam-vid -t 0 --inline --width 1640 --height 1232 --framerate 30 --bitrate 6000000 -o - | \
ffmpeg -re -i - -c:v copy -f flv "$URL"
