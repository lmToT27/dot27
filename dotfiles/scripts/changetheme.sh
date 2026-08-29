#!/usr/bin/env bash

INPUT=$1
[[ -z "$INPUT" ]] && exit 1

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR"

if [[ "$INPUT" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
    ACCENT_COLOR="#${INPUT: -6}"
else
    [[ ! -f "$INPUT" ]] && exit 1

    # AWK instead of python3: sub-ms startup vs ~15ms, matters on a hot
    # theme-change path. Only l/s (not h) feed the scoring below, so hue
    # is dropped entirely rather than ported.
    ACCENT_COLOR=$(
        magick -define jpeg:size=200x200 "$INPUT" -resize 100x100 -define kmeans:cluster-threshold=1% -kmeans 10 -format "%c" histogram:info: | \
        awk '
            match($0, /^[ \t]*[0-9]+:.*#[0-9a-fA-F]{6}/) {
                line = $0
                sub(/^[ \t]*/, "", line)
                split(line, a, ":")
                count = a[1] + 0
                if (!match(line, /#[0-9a-fA-F]{6}/)) next
                total += count
                n++
                counts[n] = count
                hexes[n] = substr(line, RSTART, RLENGTH)
            }
            END {
                best_hex = "#7aa2f7"; best_score = -1
                gray_hex = "#e5e9f0"; max_gray_l = -1
                if (total == 0) { print best_hex; exit }
                for (i = 1; i <= n; i++) {
                    c = counts[i]; hx = hexes[i]
                    if ((c / total) * 100 < 1.0) continue
                    r = strtonum("0x" substr(hx, 2, 2)) / 255.0
                    g = strtonum("0x" substr(hx, 4, 2)) / 255.0
                    b = strtonum("0x" substr(hx, 6, 2)) / 255.0
                    maxc = r; if (g > maxc) maxc = g; if (b > maxc) maxc = b
                    minc = r; if (g < minc) minc = g; if (b < minc) minc = b
                    l = (maxc + minc) / 2.0
                    if (minc == maxc) { s = 0.0 } else {
                        rangec = maxc - minc; sumc = maxc + minc
                        s = (l <= 0.5) ? rangec / sumc : rangec / (2.0 - sumc)
                    }
                    if (s < 0.15) {
                        if (l > max_gray_l && l > 0.4) { max_gray_l = l; gray_hex = hx }
                        continue
                    }
                    if (l < 0.15) continue
                    score = (s * 3.0) + l
                    if (score > best_score) { best_score = score; best_hex = hx }
                }
                print (best_score != -1) ? best_hex : gray_hex
            }
        '
    )
    [[ -z "$ACCENT_COLOR" || "$ACCENT_COLOR" == "#" ]] && ACCENT_COLOR="#7aa2f7"
fi

THEME_DIR="$HOME/.local/state/my_theme"
mkdir -p "$THEME_DIR"

# echo > file is a bash builtin redirect (no fork); piping these through
# tee instead benchmarks ~18x slower per write here, so builtins stay.
echo "@define-color accent $ACCENT_COLOR;" > "$THEME_DIR/colors.css"
echo "@define-color accent $ACCENT_COLOR;" > "$CACHE_DIR/colors.css"
echo "* { accent: $ACCENT_COLOR; accent-soft: ${ACCENT_COLOR}33; accent-highlight: bold $ACCENT_COLOR; }" > "$CACHE_DIR/colors.rasi"
echo "$ACCENT_COLOR" > "$CACHE_DIR/prompt_color.txt"
echo "export DYNAMIC_ACCENT=\"$ACCENT_COLOR\"" > "$CACHE_DIR/zsh_colors.zsh"
echo "\$accent = rgb(${ACCENT_COLOR//#/})" > "$CACHE_DIR/hyprlock-colors.conf"

[[ "$SKIP_RELOAD" == "1" ]] && exit 0

# Quickshell watches colors.css directly (Theme.qml FileView), so the bar
# picks up the new accent live — no process restart needed here anymore.
pkill -SIGUSR1 zsh
