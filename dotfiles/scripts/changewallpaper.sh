#!/usr/bin/env bash

WALLPAPER=$1
[[ ! -f "$WALLPAPER" ]] && exit 1
WALLPAPER=$(realpath "$WALLPAPER")

CACHE_DIR="$HOME/.cache/theme"
STORE_DIR="$CACHE_DIR/store"
mkdir -p "$STORE_DIR"

# Cache key from path+mtime+size (no decode needed, so this is instant even
# for huge images) lets repeat wallpapers skip blur+kmeans entirely.
KEY=$(stat -c '%n-%Y-%s' "$WALLPAPER" | sha1sum | cut -d' ' -f1)
ENTRY="$STORE_DIR/$KEY"

# Pick a random transition each time so switches don't all look the same.
TRANSITIONS=(wave wipe grow outer any)
TRANSITION="${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"
TRANSITION_ARGS=(--transition-fps 60 --transition-duration 1.4 --transition-type "$TRANSITION")

case "$TRANSITION" in
    wave)
        TRANSITION_ARGS+=(--transition-angle $((RANDOM % 360)) --transition-wave "$((15 + RANDOM % 25)),$((15 + RANDOM % 25))")
        ;;
    wipe)
        TRANSITION_ARGS+=(--transition-angle $((RANDOM % 360)))
        ;;
    grow|outer)
        TRANSITION_ARGS+=(--transition-pos "0.$((5 + RANDOM % 90)),0.$((5 + RANDOM % 90))")
        ;;
esac

# Kick off the visible transition immediately; nothing below needs to finish
# before the wallpaper starts changing on screen.
awww img "$WALLPAPER" "${TRANSITION_ARGS[@]}" &

if [[ -f "$ENTRY.jpg" && -f "$ENTRY.css" ]]; then
    cp "$ENTRY.jpg" "$CACHE_DIR/blurred_wallpaper.jpg"
    cp "$ENTRY.css" "$HOME/.local/state/my_theme/colors.css"
    cp "$ENTRY.css" "$CACHE_DIR/colors.css"
    ACCENT=$(grep -oP '#[0-9a-fA-F]{6}' "$ENTRY.css")
    echo "* { accent: $ACCENT; }" > "$CACHE_DIR/colors.rasi"
    echo "$ACCENT" > "$CACHE_DIR/prompt_color.txt"
    echo "export DYNAMIC_ACCENT=\"$ACCENT\"" > "$CACHE_DIR/zsh_colors.zsh"
else
    magick -define jpeg:size=1280x720 "$WALLPAPER" -resize "640x360>" -blur 0x8 "$CACHE_DIR/blurred_wallpaper.jpg" &
    PID_BLUR=$!

    SKIP_RELOAD=1 changetheme.sh "$WALLPAPER" &
    PID_THEME=$!

    wait $PID_BLUR
    wait $PID_THEME

    cp "$CACHE_DIR/blurred_wallpaper.jpg" "$ENTRY.jpg"
    cp "$CACHE_DIR/colors.css" "$ENTRY.css"
fi

pkill -x swaybg 2>/dev/null
swaybg -i "$CACHE_DIR/blurred_wallpaper.jpg" -m fill </dev/null >/dev/null 2>&1 &

# changetheme.sh (or the cache-hit branch above) already wrote the accent;
# the bar picks it up live via Quickshell's FileView watch, no restart needed.
pkill -SIGUSR1 zsh
