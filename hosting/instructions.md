# Hosting Setup Instructions

## 1. Run setup

```bash
chmod +x setup.sh
./setup.sh
```

This installs dependencies, creates a Python venv, and copies `.env.example` to `.env` if needed.

## 2. Configure `.env`

Edit `hosting/.env` with your actual values:

```
ZELVAKCAM_PASSWORD=your_password
FLASK_SECRET_KEY=your_secret_key
SERVER_IP=134.122.67.47
FLASK_PORT=8080
```

## 3. Configure NGINX

Edit the NGINX configuration file:

```bash
sudo nano /etc/nginx/nginx.conf
```

Add the following configuration:

```nginx
rtmp {
    server {
        listen 1935;

        application live {
            live on;
            record off;

            hls on;
            hls_path /tmp/hls;
            hls_fragment 2s;
            hls_playlist_length 10s;
        }
    }
}

http {
    server {
        listen 127.0.0.1:8081;

        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }
            root /tmp;
            add_header Cache-Control no-cache;
        }
    }
}
```

Note: NGINX HLS listens on `127.0.0.1:8081` (localhost only). Flask proxies HLS requests after authentication, so CORS headers are not needed.

## 4. Restart NGINX

```bash
sudo systemctl restart nginx
```

## 5. Make `run_server.sh` executable and start the server

```bash
chmod +x run_server.sh
./run_server.sh
```
