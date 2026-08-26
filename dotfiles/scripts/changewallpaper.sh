#!/usr/bin/env bash

WALLPAPER=$1
[[ ! -f "$WALLPAPER" ]] && exit 1

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR"

magick "$WALLPAPER" -resize 25% -blur 0x15 "$CACHE_DIR/blurred_wallpaper.jpg" &
PID_BLUR=$!

SKIP_RELOAD=1 changetheme.sh "$WALLPAPER" &
PID_THEME=$!

wait $PID_BLUR
wait $PID_THEME

awww img "$WALLPAPER" --transition-fps 60 --transition-type wave --transition-angle 90 --transition-duration 1.5 &

pkill -x swaybg 2>/dev/null
swaybg -i "$CACHE_DIR/blurred_wallpaper.jpg" -m fill </dev/null >/dev/null 2>&1 &

# changetheme.sh (called above) already handled the accent reload; the bar
# picks it up live via Quickshell's FileView watch, no restart needed.
pkill -SIGUSR1 zsh
