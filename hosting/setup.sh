#!/bin/bash
# Idempotent setup for the droplet (Ubuntu/Debian). Run as a normal user with sudo.
set -euo pipefail

MEDIAMTX_VERSION="v1.9.3"
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

sudo apt-get update
sudo apt-get install -y python3 python3-venv curl gettext-base ufw openssl \
    debian-keyring debian-archive-keyring apt-transport-https gpg

# Caddy (official repo)
if ! command -v caddy >/dev/null; then
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor --yes -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list >/dev/null
    sudo apt-get update
    sudo apt-get install -y caddy
fi

# MediaMTX (pinned)
if ! command -v mediamtx >/dev/null || ! mediamtx --version 2>&1 | grep -q "${MEDIAMTX_VERSION#v}"; then
    case "$(uname -m)" in
        x86_64) ARCH=amd64 ;;
        aarch64) ARCH=arm64v8 ;;
        armv7l) ARCH=armv7 ;;
        *) echo "Unsupported arch $(uname -m)"; exit 1 ;;
    esac
    TMP="$(mktemp -d)"
    curl -fsSL "https://github.com/bluenviron/mediamtx/releases/download/${MEDIAMTX_VERSION}/mediamtx_${MEDIAMTX_VERSION}_linux_${ARCH}.tar.gz" | tar -xz -C "$TMP" mediamtx
    sudo install -m 755 "$TMP/mediamtx" /usr/local/bin/mediamtx
    rm -rf "$TMP"
fi

# Python app
python3 -m venv venv
./venv/bin/pip install -q -r requirements.txt

# .env with generated secrets
if [ ! -f .env ]; then
    read -rsp "Choose the web login password: " PW; echo
    case "$PW" in ""|*"'"*|changeme) echo "Password must be non-empty, not 'changeme', and contain no single quote."; exit 1;; esac
    SERVER_IP_GUESS="$(curl -fsS https://api.ipify.org || true)"
    umask 077
    {
        printf "ZELVAKCAM_PASSWORD='%s'\n" "$PW"
        printf 'FLASK_SECRET_KEY=%s\n' "$(openssl rand -hex 32)"
        printf 'SERVER_IP=%s\n' "${SERVER_IP_GUESS:-127.0.0.1}"
        printf 'DOMAIN=\n'
        printf 'PUBLISH_KEY=%s\n' "$(openssl rand -hex 16)"
        printf 'FLASK_PORT=8080\n'
    } > .env
    chmod 600 .env
fi
envget() { grep -m1 "^$1=" .env | cut -d= -f2- || true; }
SERVER_IP="$(envget SERVER_IP)"; PUBLISH_KEY="$(envget PUBLISH_KEY)"; DOMAIN="$(envget DOMAIN)"
: "${DOMAIN:=${SERVER_IP//./-}.sslip.io}"
export SERVER_IP PUBLISH_KEY DOMAIN

# MediaMTX config
id -u mediamtx &>/dev/null || sudo useradd -r -s /usr/sbin/nologin mediamtx
sudo mkdir -p /etc/mediamtx
envsubst '${SERVER_IP} ${PUBLISH_KEY}' < deploy/mediamtx.yml.template | sudo tee /etc/mediamtx/mediamtx.yml >/dev/null
sudo chown root:mediamtx /etc/mediamtx/mediamtx.yml
sudo chmod 640 /etc/mediamtx/mediamtx.yml
sudo install -m 644 deploy/mediamtx.service /etc/systemd/system/mediamtx.service

# Caddy config
envsubst '${DOMAIN}' < deploy/Caddyfile.template | sudo tee /etc/caddy/Caddyfile >/dev/null

# Web service
sed -e "s|__DIR__|${DIR}|g" -e "s|__USER__|$(id -un)|g" deploy/zelvakcam-web.service | sudo tee /etc/systemd/system/zelvakcam-web.service >/dev/null

# Old nginx-rtmp setup is replaced
if systemctl list-unit-files nginx.service &>/dev/null; then
    sudo systemctl disable --now nginx 2>/dev/null || true
fi

# Firewall
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 1935/tcp
sudo ufw allow 8189/udp
sudo ufw allow 8189/tcp
sudo ufw --force enable

sudo systemctl daemon-reload
sudo systemctl enable mediamtx zelvakcam-web caddy
sudo systemctl restart mediamtx zelvakcam-web caddy

echo
echo "Done. Web UI:  https://${DOMAIN}"
echo "On the Pi set in /etc/zelvakcam.conf:"
echo "  RTMP_URL='rtmp://${SERVER_IP}/cam?user=pi&pass=${PUBLISH_KEY}'"
