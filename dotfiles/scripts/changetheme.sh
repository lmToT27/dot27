#!/usr/bin/env bash

INPUT=$1
if [ -z "$INPUT" ]; then
    echo "Error: Please provide a valid wallpaper path or a hex color code (e.g., FFFFFF or #FFFFFF)."
    exit 1
fi

# Check if the input is a valid hex color code (with or without '#')
if [[ "$INPUT" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
    # Prepend '#' if missing
    if [[ "$INPUT" != \#* ]]; then
        ACCENT_COLOR="#$INPUT"
    else
        ACCENT_COLOR="$INPUT"
    fi
else
    # Treat input as a wallpaper path and extract color using ColorThief
    WALLPAPER="$INPUT"
    
    if [ ! -f "$WALLPAPER" ]; then
        echo "Error: Wallpaper file '$WALLPAPER' not found."
        exit 1
    fi

    ACCENT_COLOR=$(magick "$WALLPAPER" -resize 1x1 -modulate 100,200,100 -format "%[hex:u.p{0,0}]\n" info: | awk '{print "#"$1}')
    
    if [ -z "$ACCENT_COLOR" ] || [ "$ACCENT_COLOR" == "#" ]; then
        ACCENT_COLOR="#7aa2f7"
    fi
fi

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR"
echo "@define-color accent $ACCENT_COLOR;" > "$CACHE_DIR/colors.css"
echo "* { accent: $ACCENT_COLOR; }" > "$CACHE_DIR/colors.rasi"
echo "$ACCENT_COLOR" > "$CACHE_DIR/prompt_color.txt"

NIRI_CONFIG="$HOME/dot27/dotfiles/niri/config.kdl"
sed -i "s/active-color \".*\"/active-color \"$ACCENT_COLOR\"/" "$NIRI_CONFIG"

niri msg action reload-config 2>/dev/null

killall -SIGUSR2 waybar 2>/dev/null
killall -SIGUSR2 swaync 2>/dev/null

echo "Accent color applied: $ACCENT_COLOR"
