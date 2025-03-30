1. Run `chmod +x setup.sh`
2. Run `setup.sh`
2. Edit the NGINX configuration file:
   ```shell
   sudo nano /etc/nginx/nginx.conf
   ```
   Add the following configuration:
   ```nginx
    rtmp {
        server {
            listen 1935;  # RTMP Port

            application live {
                live on;
                record off;

                # HLS Configuration
                hls on;
                hls_path /tmp/hls;
                hls_fragment 2s;
                hls_playlist_length 10s;
            }
        }
    }

    http {
       server {
           listen 8081;
   
           location /hls {
               types {
                   application/vnd.apple.mpegurl m3u8;
                   video/mp2t ts;
               }
               root /tmp;
               add_header Cache-Control no-cache;
   
               # Add CORS headers
               add_header 'Access-Control-Allow-Origin' 'http://http://134.122.67.47:8080' always;
               add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
               add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
            
               # Handle preflight requests
               if ($request_method = 'OPTIONS') {
                   add_header 'Access-Control-Allow-Origin' 'http://http://134.122.67.47:8080' always;
                   add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;
                   add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range' always;
                   add_header 'Access-Control-Max-Age' 1728000;
                   add_header 'Content-Type' 'text/plain; charset=utf-8';
                   add_header 'Content-Length' 0;
                   return 204;
               }
           }
       }
   }
   ```
3. Restart NGINX:
   ```shell
   sudo systemctl restart nginx
   ```
   
4. Make `run_server.sh` executable:
   ```shell
   chmod +x ~/run_server.sh
   ```
   
5Run `run_server.sh` to start the web server:
   ```shell
    ./run_server.sh
    ```
