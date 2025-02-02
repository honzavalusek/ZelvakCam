#!/bin/bash

URL="rtmp://134.122.67.47/live/stream"

rpicam-vid -t 0 --inline --framerate 30 --width 1280 --height 720 --codec h264 \
--profile high --level 4.2 --bitrate 3500000 -o - | \
ffmpeg -re -f h264 -i - -c:v copy -f flv $URL