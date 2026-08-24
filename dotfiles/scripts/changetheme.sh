#!/usr/bin/env bash

INPUT=$1
[[ -z "$INPUT" ]] && exit 1

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR"

if [[ "$INPUT" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
    ACCENT_COLOR="#${INPUT: -6}"
else
    [[ ! -f "$INPUT" ]] && exit 1
    
    ACCENT_COLOR=$(
        magick "$INPUT" -resize 200x200 -kmeans 10 -format "%c" histogram:info: | \
        python3 -c "
import sys, colorsys, re
total = 0; colors = []
for l in sys.stdin:
    cm = re.search(r'^\s*(\d+):', l)
    hm = re.search(r'(#[0-9a-fA-F]{6})', l, re.I)
    if cm and hm:
        c = int(cm.group(1)); total += c
        colors.append((c, hm.group(1)))

best_hex = '#7aa2f7'; best_score = -1
grayscale_hex = '#e5e9f0'; max_gray_l = -1

for c, hx in colors:
    if (c / total) * 100 < 1.0: continue
    r, g, b = (int(hx[i:i+2], 16)/255.0 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    if s < 0.15:
        if l > max_gray_l and l > 0.4: max_gray_l = l; grayscale_hex = hx
        continue
    if l < 0.15: continue
    score = (s * 3.0) + l
    if score > best_score: best_score = score; best_hex = hx
print(best_hex if best_score != -1 else grayscale_hex)
"
    )   
    [[ -z "$ACCENT_COLOR" || "$ACCENT_COLOR" == "#" ]] && ACCENT_COLOR="#7aa2f7"
fi

THEME_DIR="$HOME/.local/state/my_theme"
mkdir -p "$THEME_DIR"

echo "@define-color accent $ACCENT_COLOR;" > "$THEME_DIR/colors.css"
echo "@define-color accent $ACCENT_COLOR;" > "$CACHE_DIR/colors.css"
echo "* { accent: $ACCENT_COLOR; }" > "$CACHE_DIR/colors.rasi"
echo "$ACCENT_COLOR" > "$CACHE_DIR/prompt_color.txt"
echo "export DYNAMIC_ACCENT=\"$ACCENT_COLOR\"" > "$CACHE_DIR/zsh_colors.zsh"

[[ "$SKIP_RELOAD" == "1" ]] && exit 0

(
    kill $(cat /tmp/waybar-main.pid 2>/dev/null) 2>/dev/null || pkill -x waybar
    pkill -x cava
    pkill -USR2 swaync
    pkill -SIGUSR1 zsh
    waybar -c "$HOME/.config/waybar/config" -s "$HOME/.config/waybar/style.css" </dev/null >/dev/null 2>&1 &
    echo $! > /tmp/waybar-main.pid
) &
