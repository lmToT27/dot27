#!/usr/bin/env bash
# Pre-warms wallpaper-picker thumbnails so the panel loads cached 280x180
# JPEGs instead of decoding full 4K originals on the render path.

CACHE_DIR="$HOME/.cache/wallpaper-thumbs"
mkdir -p "$CACHE_DIR"

shopt -s nullglob
for f in "$HOME"/Pictures/Wallpapers/*.{jpg,jpeg,png,webp}; do
    thumb="$CACHE_DIR/$(basename "${f%.*}").jpg"
    [[ -f "$thumb" && "$thumb" -nt "$f" ]] && continue
    magick "$f" -resize 280x180^ -gravity center -extent 280x180 "$thumb"
done
