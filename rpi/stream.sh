#!/bin/bash

URL="rtmp://134.122.67.47/live/stream"

rpicam-vid -t 0 --inline --width 1640 --height 1232 --framerate 40 --bitrate 6000000 -o - | \
ffmpeg -re -i - -c:v copy -f flv $URL
