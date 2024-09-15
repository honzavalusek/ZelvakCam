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
            listen 1935;
            chunk_size 4096;
    
            application live {
                live on;
                record off;
                # Optional: Restrict access
                allow publish all;
                allow play all;
            }
        }
    }
   ```
3. Restart NGINX:
   ```shell
   sudo systemctl restart nginx
   ```
4. Make `start_ffmpeg.sh` executable:
   ```shell
   chmod +x ~/start_ffmpeg.sh
   ```
   
5. Make `run_server.sh` executable:
   ```shell
   chmod +x ~/run_server.sh
   ```
   
7. Run `start_ffmpeg.sh` to start receiving the stream:
   ```shell
   ./start_ffmpeg.sh
   ```
   
8. Run `run_server.sh` to start the web server:
   ```shell
    ./run_server.sh
    ```
