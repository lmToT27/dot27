#!/usr/bin/env bash

WALLPAPER=$1
if [ -z "$WALLPAPER" ]; then
    echo "Usage: changewallpaper.sh /path/to/image.jpg"
    exit 1
fi

if ! pidof awww-daemon > /dev/null; then
    awww-daemon &
    sleep 0.5
fi

awww img "$WALLPAPER" \
    --transition-bezier .43,1.19,1,.4 \
    --transition-fps 60 \
    --transition-type grow \
    --transition-pos 0.5,0.5 \
    --transition-duration 1.5

changetheme.sh "$WALLPAPER"
