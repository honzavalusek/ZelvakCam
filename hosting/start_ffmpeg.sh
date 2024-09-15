#!/bin/bash

ffmpeg -i rtmp://localhost/live/stream -c:v copy -c:a copy \
-f hls -hls_time 1 -hls_list_size 5 -hls_flags delete_segments+append_list \
-hls_allow_cache 0 ./static/hls/stream.m3u8
