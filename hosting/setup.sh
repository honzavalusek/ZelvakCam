#!/bin/bash
set -euo pipefail

mkdir -p ./static/hls

sudo apt update
sudo apt install -y nginx libnginx-mod-rtmp python3 python3-pip python3-venv ffmpeg

python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env from .env.example — please edit it with your actual values."
fi