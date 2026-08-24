#!/usr/bin/env bash

INPUT=$1
if [ -z "$INPUT" ]; then
    exit 1
fi

if [[ "$INPUT" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
    if [[ "$INPUT" != \#* ]]; then
        ACCENT_COLOR="#$INPUT"
    else
        ACCENT_COLOR="$INPUT"
    fi
else
    WALLPAPER="$INPUT"
    
    if [ ! -f "$WALLPAPER" ]; then
        exit 1
    fi

    ACCENT_COLOR=$(
        area=$(magick "$WALLPAPER" -resize 200x200 -format "%[fx:w*h]" info:)
        
        magick "$WALLPAPER" -resize 200x200 -kmeans 10 -format "%c" histogram:info: \
        | sed 's/://g' | awk -v area=$area '{print 100*$1/area, $3}' \
        | python3 -c "
import sys, colorsys
lines = sys.stdin.readlines()
best_hex = '#7aa2f7'
best_score = -1
grayscale_hex = '#e5e9f0' 
max_gray_l = -1
for line in lines:
    parts = line.strip().split()
    if len(parts) != 2: continue
    percent = float(parts[0])
    hx = parts[1][:7]
    if percent < 1.0: continue
    r, g, b = tuple(int(hx[i:i+2], 16)/255.0 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    if s < 0.15:
        if l > max_gray_l and l > 0.4:
            max_gray_l = l
            grayscale_hex = hx
        continue
    if l < 0.15: continue
    score = (s * 3.0) + l
    if score > best_score:
        best_score = score
        best_hex = hx
if best_score != -1:
    print(best_hex)
else:
    print(grayscale_hex)
"
    )   
    if [ -z "$ACCENT_COLOR" ] || [ "$ACCENT_COLOR" == "#" ]; then
        ACCENT_COLOR="#7aa2f7"
    fi
fi

THEME_DIR="$HOME/.local/state/my_theme"
mkdir -p "$THEME_DIR"
echo "@define-color accent $ACCENT_COLOR;" > "$THEME_DIR/colors.css"

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR"
echo "@define-color accent $ACCENT_COLOR;" > "$CACHE_DIR/colors.css"
echo "* { accent: $ACCENT_COLOR; }" > "$CACHE_DIR/colors.rasi"
echo "$ACCENT_COLOR" > "$CACHE_DIR/prompt_color.txt"
echo "export DYNAMIC_ACCENT=\"$ACCENT_COLOR\"" > "$CACHE_DIR/zsh_colors.zsh"

if [ -f /tmp/waybar-main.pid ]; then
    kill $(cat /tmp/waybar-main.pid) 2>/dev/null
else
    pkill -f "waybar -c ~/.config/waybar/config " 2>/dev/null
fi

pkill -USR2 swaync 2>/dev/null
pkill -SIGUSR1 zsh 2>/dev/null

sleep 0.5

waybar -c "$HOME/.config/waybar/config" -s "$HOME/.config/waybar/style.css" >/dev/null 2>&1 &
echo $! > /tmp/waybar-main.pid

echo "Accent color applied: $ACCENT_COLOR"
