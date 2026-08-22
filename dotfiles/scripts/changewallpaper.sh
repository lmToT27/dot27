#!/usr/bin/env bash

WALLPAPER=$1
if [ -z "$WALLPAPER" ]; then
    echo "Usage: changewallpaper.sh /path/to/image.jpg"
    exit 1
fi

killall swaybg
swaybg -i "$WALLPAPER" -m fill &

changetheme.sh "$WALLPAPER"
