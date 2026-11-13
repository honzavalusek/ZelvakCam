#!/bin/bash
# Streams the Pi camera as H.264 (no re-encode) to the RTMP server.
set -euo pipefail

[ -f /etc/zelvakcam.conf ] && source /etc/zelvakcam.conf

: "${RTMP_URL:?Set RTMP_URL in /etc/zelvakcam.conf}"
WIDTH="${WIDTH:-1280}"
HEIGHT="${HEIGHT:-720}"
FPS="${FPS:-30}"
BITRATE="${BITRATE:-2500000}"
# Extra rpicam-vid options, e.g. "--mode 1640:1232" for the full sensor field of view
EXTRA_ARGS="${EXTRA_ARGS:-}"

# Baseline profile + 1s keyframe interval: browser-friendly (WebRTC) and fast to join.
rpicam-vid -t 0 -n --inline --codec h264 --profile baseline --level 4.1 \
    --intra "$FPS" --width "$WIDTH" --height "$HEIGHT" \
    --framerate "$FPS" --bitrate "$BITRATE" $EXTRA_ARGS -o - \
  | ffmpeg -hide_banner -loglevel warning \
      -fflags +genpts -use_wallclock_as_timestamps 1 \
      -f h264 -framerate "$FPS" -i - \
      -c:v copy -f flv "$RTMP_URL"
