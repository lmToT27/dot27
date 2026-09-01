#!/usr/bin/env bash

INPUT=$1
[[ -z "$INPUT" ]] && exit 1

CACHE_DIR="$HOME/.cache/theme"
mkdir -p "$CACHE_DIR"

THEME_MODE="${THEME_MODE:-$(cat "$CACHE_DIR/mode" 2>/dev/null || echo dark)}"

if [[ "$INPUT" =~ ^#?[0-9a-fA-F]{6}$ ]]; then
    ACCENT_COLOR="#${INPUT: -6}"
else
    [[ ! -f "$INPUT" ]] && exit 1

    ACCENT_COLOR=$(
        magick -define jpeg:size=200x200 "$INPUT" -resize 100x100 -define kmeans:cluster-threshold=1% -kmeans 10 -format "%c" histogram:info: | \
        awk -v mode="$THEME_MODE" '
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
                is_light = (mode == "light")
                best_hex = is_light ? "#2a3158" : "#7aa2f7"; best_score = -1
                gray_hex = is_light ? "#3a3a3a" : "#e5e9f0"; best_gray_l = -1
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
                        gray_l = is_light ? (1.0 - l) : l
                        if (gray_l > best_gray_l && gray_l > 0.4) { best_gray_l = gray_l; gray_hex = hx }
                        continue
                    }
                    if (is_light ? (l > 0.85) : (l < 0.15)) continue
                    score = (s * 3.0) + (is_light ? (1.0 - l) : l)
                    if (score > best_score) { best_score = score; best_hex = hx }
                }
                print (best_score != -1) ? best_hex : gray_hex
            }
        '
    )
    [[ -z "$ACCENT_COLOR" || "$ACCENT_COLOR" == "#" ]] && ACCENT_COLOR=$([[ "$THEME_MODE" == "light" ]] && echo "#2a3158" || echo "#7aa2f7")
fi

if [[ "$THEME_MODE" == "light" ]]; then
    BG_COLOR="#ffffff"
    FG_COLOR="#111111"
    HYPR_BG_COLOR="$BG_COLOR"
    HOVER_COLOR="#e6e6e6" 
    KITTY_THEME="$HOME/.config/kitty/themes/tokyonight-light.conf"
    
    ZSH_RED="#C64343"
    ZSH_ORANGE="#B05A2E"
    ZSH_YELLOW="#8C6C3E"
    ZSH_GREEN="#485E30"
    ZSH_CYAN="#316182"
    ZSH_BLUE="#2A3158"
    ZSH_PURPLE="#5A4A78"
    ZSH_MAGENTA="#894B65"
    ZSH_MUTED="#545C7E"
    
    FZF_COLORS="--color=bg+:#e6e6e6,fg+:#111111,hl:#C64343,hl+:#C64343,prompt:#316182,pointer:#C64343,marker:#485E30,info:#8C6C3E,spinner:#894B65,header:#316182"
    BAT_THEME="OneHalfLight"
else
    BG_COLOR="#000000"
    FG_COLOR="#ffffff"
    HYPR_BG_COLOR="#191414" 
    HOVER_COLOR="#1a1a1a"
    KITTY_THEME="$HOME/.config/kitty/themes/tokyonight-dark.conf"
    
    ZSH_RED="#f7768e"
    ZSH_ORANGE="#ff9e64"
    ZSH_YELLOW="#e0af68"
    ZSH_GREEN="#9ece6a"
    ZSH_CYAN="#7dcfff" 
    ZSH_BLUE="#7aa2f7"
    ZSH_PURPLE="#bb9af7"
    ZSH_MAGENTA="#c678dd"
    ZSH_MUTED="#a9b1d6" 
    
    FZF_COLORS="--color=bg+:#1a1a1a,fg+:#ffffff,hl:#f7768e,hl+:#f7768e,prompt:#7dcfff,pointer:#f7768e,marker:#9ece6a,info:#e0af68,spinner:#bb9af7,header:#7dcfff"
    BAT_THEME="tokyonight_night"
fi

THEME_DIR="$HOME/.local/state/my_theme"
mkdir -p "$THEME_DIR"

printf '@define-color accent %s;\n@define-color bg %s;\n@define-color fg %s;\n' "$ACCENT_COLOR" "$BG_COLOR" "$FG_COLOR" > "$THEME_DIR/colors.css"
printf '@define-color accent %s;\n@define-color bg %s;\n@define-color fg %s;\n' "$ACCENT_COLOR" "$BG_COLOR" "$FG_COLOR" > "$CACHE_DIR/colors.css"
echo "* { accent: $ACCENT_COLOR; accent-soft: ${ACCENT_COLOR}33; accent-highlight: bold $ACCENT_COLOR; bg-base: $BG_COLOR; fg: $FG_COLOR; bg-hover: $HOVER_COLOR; placeholder: ${FG_COLOR}4d; }" > "$CACHE_DIR/colors.rasi"
echo "$ACCENT_COLOR" > "$CACHE_DIR/prompt_color.txt"

printf 'export DYNAMIC_ACCENT="%s"\nexport ZSH_C_PURPLE="%s"\nexport ZSH_C_RED="%s"\nexport ZSH_C_ORANGE="%s"\nexport ZSH_C_YELLOW="%s"\nexport ZSH_C_GREEN="%s"\nexport ZSH_C_MUTED="%s"\nexport ZSH_C_CYAN="%s"\nexport ZSH_C_BLUE="%s"\nexport ZSH_C_MAGENTA="%s"\nexport FZF_COLORS="%s"\nexport BAT_THEME="%s"\n' \
    "$ACCENT_COLOR" "$ZSH_PURPLE" "$ZSH_RED" "$ZSH_ORANGE" "$ZSH_YELLOW" "$ZSH_GREEN" "$ZSH_MUTED" "$ZSH_CYAN" "$ZSH_BLUE" "$ZSH_MAGENTA" "$FZF_COLORS" "$BAT_THEME" > "$CACHE_DIR/zsh_colors.zsh"

printf '$accent = rgb(%s)\n$bg_color = rgb(%s)\n$text_color = rgb(%s)\n' "${ACCENT_COLOR//#/}" "${HYPR_BG_COLOR//#/}" "${FG_COLOR//#/}" > "$CACHE_DIR/hyprlock-colors.conf"
cp "$KITTY_THEME" "$CACHE_DIR/kitty-colors.conf"

dconf write /org/gnome/desktop/interface/color-scheme "'$([[ "$THEME_MODE" == "light" ]] && echo default || echo prefer-dark)'" 2>/dev/null || true

[[ "$SKIP_RELOAD" == "1" ]] && exit 0

pkill -SIGUSR1 zsh
for sock in /tmp/kitty-*; do
    [[ -S "$sock" ]] || continue
    kitty @ --to "unix:$sock" set-colors -a "$CACHE_DIR/kitty-colors.conf" >/dev/null 2>&1 || true
done
