#!/usr/bin/env bash

WALLPAPER=$1
if [ -z "$WALLPAPER" ]; then
    echo "Error: Please provide a valid wallpaper path."
    exit 1
fi

ACCENT_COLOR=$(python3 -c "
from colorthief import ColorThief
import colorsys

try:
    ct = ColorThief('$WALLPAPER')
    dom = ct.get_color(quality=1)
    r, g, b = [x/255.0 for x in dom]
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    l = max(0.65, l)
    r, g, b = colorsys.hls_to_rgb(h, l, s)
    print(f'#{int(r*255):02x}{int(g*255):02x}{int(b*255):02x}')
except Exception:
    print('#7aa2f7')
")

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR"
echo "@define-color accent $ACCENT_COLOR;" > "$CACHE_DIR/colors.css"
echo "* { accent: $ACCENT_COLOR; }" > "$CACHE_DIR/colors.rasi"
echo "$ACCENT_COLOR" > "$CACHE_DIR/prompt_color.txt"

NIRI_CONFIG="$HOME/dot27/dotfiles/niri/config.kdl"
sed -i "s/active-color \".*\"/active-color \"$ACCENT_COLOR\"/" "$NIRI_CONFIG"

killall -SIGUSR2 waybar 2>/dev/null
killall -SIGUSR2 swaync 2>/dev/null
