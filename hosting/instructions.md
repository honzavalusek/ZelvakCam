# Hosting setup

On the droplet (Ubuntu/Debian):

```bash
cd hosting
./setup.sh
```

It installs MediaMTX + Caddy, creates `.env` (asks for the login password, generates the secrets), configures HTTPS via `<ip>.sslip.io` (or your `DOMAIN` from `.env`), opens the firewall and starts three systemd services: `mediamtx`, `zelvakcam-web`, `caddy`.

At the end it prints the web URL and the `RTMP_URL` for the Pi. Re-running is safe (idempotent); edit `.env` and re-run to apply changes.

Ports: 22, 80, 443 (tcp), 1935 (tcp, Pi ingest, needs `PUBLISH_KEY`), 8189 (udp/tcp, WebRTC media).
Logs: `journalctl -u mediamtx -u zelvakcam-web -u caddy -f`
