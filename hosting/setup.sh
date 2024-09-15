#!/bin/bash

mkdir -p ./static/hls

sudo apt update
sudo apt install nginx libnginx-mod-rtmp python3 python3-pip python3-venv ffmpeg

python3 -m venv venv
source venv/bin/activate
pip3 install -r requirements.txt