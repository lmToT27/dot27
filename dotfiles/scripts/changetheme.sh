#!/usr/bin/env bash

WALLPAPER=$1
if [ -z "$WALLPAPER" ]; then
    echo "Error: Please provide a valid wallpaper path."
    exit 1
fi

ACCENT_COLOR=$(python3 -c "
from colorthief import ColorThief
try:
    ct = ColorThief('$WALLPAPER')
    dom = ct.get_color(quality=1)
    print(f'#{dom[0]:02x}{dom[1]:02x}{dom[2]:02x}')
except Exception:
    print('#7aa2f7')
")

CACHE_DIR=\"$HOME/.cache/theme\"
mkdir -p \"$CACHE_DIR\"
echo \"@define-color accent $ACCENT_COLOR;\" > \"$CACHE_DIR/colors.css\"
echo \"* { accent: $ACCENT_COLOR; }\" > \"$CACHE_DIR/colors.rasi\"

NIRI_CONFIG=\"$HOME/dot27/dotfiles/niri/config.kdl\"
sed -i \"s/active-color \\\".*\\\"/active-color \\\"$ACCENT_COLOR\\\"/\" \"$NIRI_CONFIG\"

killall -SIGUSR2 waybar
killall -SIGUSR2 swaync
