#!/usr/bin/env bash

WALLPAPER=$1
[[ ! -f "$WALLPAPER" ]] && exit 1
WALLPAPER=$(realpath "$WALLPAPER")

CACHE_DIR="$HOME/.cache/theme"
STORE_DIR="$CACHE_DIR/store"
mkdir -p "$STORE_DIR"

# Falls back to the persisted mode, not a hardcoded "dark", so picking a
# new wallpaper keeps the current light/dark choice.
THEME_MODE="${THEME_MODE:-$(cat "$CACHE_DIR/mode" 2>/dev/null || echo dark)}"
echo "$WALLPAPER" > "$CACHE_DIR/current_wallpaper.txt"

KEY=$(stat -c '%n-%Y-%s' "$WALLPAPER" | sha1sum)
KEY="${KEY%% *}-$THEME_MODE"
ENTRY="$STORE_DIR/$KEY"

TRANSITIONS=(wave wipe grow outer any)
TRANSITION="${TRANSITIONS[RANDOM % ${#TRANSITIONS[@]}]}"
TRANSITION_ARGS=(--transition-fps 120 --transition-duration 1.4 --transition-type "$TRANSITION")

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

awww img "$WALLPAPER" "${TRANSITION_ARGS[@]}" &

if [[ -f "$ENTRY.jpg" && -f "$ENTRY.css" ]]; then
    cp "$ENTRY.jpg" "$CACHE_DIR/blurred_wallpaper.jpg"
    cp "$ENTRY.css" "$HOME/.local/state/my_theme/colors.css"
    cp "$ENTRY.css" "$CACHE_DIR/colors.css"

    CSS_CONTENT=$(<"$ENTRY.css")
    [[ "$CSS_CONTENT" =~ accent[[:space:]]+(#[0-9a-fA-F]{6}) ]] && ACCENT="${BASH_REMATCH[1]}"
    if [[ "$CSS_CONTENT" =~ bg[[:space:]]+(#[0-9a-fA-F]{6}) ]]; then
        BG="${BASH_REMATCH[1]}"
    else
        BG=$([[ "$THEME_MODE" == "light" ]] && echo "#ffffff" || echo "#000000")
    fi
    if [[ "$CSS_CONTENT" =~ fg[[:space:]]+(#[0-9a-fA-F]{6}) ]]; then
        FG="${BASH_REMATCH[1]}"
    else
        FG=$([[ "$THEME_MODE" == "light" ]] && echo "#111111" || echo "#ffffff")
    fi

    HOVER=$([[ "$THEME_MODE" == "light" ]] && echo "#e6e6e6" || echo "#1a1a1a")
    echo "* { accent: $ACCENT; accent-soft: ${ACCENT}33; accent-highlight: bold $ACCENT; bg-base: $BG; fg: $FG; bg-hover: $HOVER; placeholder: ${FG}4d; }" > "$CACHE_DIR/colors.rasi"
    echo "$ACCENT" > "$CACHE_DIR/prompt_color.txt"
    HYPR_BG=$([[ "$THEME_MODE" == "light" ]] && echo "#ffffff" || echo "#191414") # soft off-black
    printf '$accent = rgb(%s)\n$bg_color = rgb(%s)\n$text_color = rgb(%s)\n' "${ACCENT//#/}" "${HYPR_BG//#/}" "${FG//#/}" > "$CACHE_DIR/hyprlock-colors.conf"

    # Mode-only (not accent-derived) — must mirror changetheme.sh's set
    # exactly, or a cache-hit here silently drops fields it doesn't know
    # about (e.g. FZF_COLORS/BAT_THEME falling back to dark defaults).
    if [[ "$THEME_MODE" == "light" ]]; then
        KITTY_THEME="$HOME/.config/kitty/themes/tokyonight-light.conf"
        ZSH_RED="#C64343"; ZSH_ORANGE="#B05A2E"; ZSH_YELLOW="#8C6C3E"
        ZSH_GREEN="#485E30"; ZSH_CYAN="#316182"; ZSH_BLUE="#2A3158"
        ZSH_PURPLE="#5A4A78"; ZSH_MAGENTA="#894B65"; ZSH_MUTED="#545C7E"
        FZF_COLORS="--color=bg+:#e6e6e6,fg+:#111111,hl:#C64343,hl+:#C64343,prompt:#316182,pointer:#C64343,marker:#485E30,info:#8C6C3E,spinner:#894B65,header:#316182"
        BAT_THEME="OneHalfLight"
    else
        KITTY_THEME="$HOME/.config/kitty/themes/tokyonight-dark.conf"
        ZSH_RED="#f7768e"; ZSH_ORANGE="#ff9e64"; ZSH_YELLOW="#e0af68"
        ZSH_GREEN="#9ece6a"; ZSH_CYAN="#7dcfff"; ZSH_BLUE="#7aa2f7"
        ZSH_PURPLE="#bb9af7"; ZSH_MAGENTA="#c678dd"; ZSH_MUTED="#a9b1d6"
        FZF_COLORS="--color=bg+:#1a1a1a,fg+:#ffffff,hl:#f7768e,hl+:#f7768e,prompt:#7dcfff,pointer:#f7768e,marker:#9ece6a,info:#e0af68,spinner:#bb9af7,header:#7dcfff"
        BAT_THEME="tokyonight_night"
    fi
    printf 'export DYNAMIC_ACCENT="%s"\nexport ZSH_C_PURPLE="%s"\nexport ZSH_C_RED="%s"\nexport ZSH_C_ORANGE="%s"\nexport ZSH_C_YELLOW="%s"\nexport ZSH_C_GREEN="%s"\nexport ZSH_C_MUTED="%s"\nexport ZSH_C_CYAN="%s"\nexport ZSH_C_BLUE="%s"\nexport ZSH_C_MAGENTA="%s"\nexport FZF_COLORS="%s"\nexport BAT_THEME="%s"\n' \
        "$ACCENT" "$ZSH_PURPLE" "$ZSH_RED" "$ZSH_ORANGE" "$ZSH_YELLOW" "$ZSH_GREEN" "$ZSH_MUTED" "$ZSH_CYAN" "$ZSH_BLUE" "$ZSH_MAGENTA" "$FZF_COLORS" "$BAT_THEME" > "$CACHE_DIR/zsh_colors.zsh"
    cp "$KITTY_THEME" "$CACHE_DIR/kitty-colors.conf"
    for sock in /tmp/kitty-*; do
        [[ -S "$sock" ]] || continue
        kitty @ --to "unix:$sock" set-colors -a "$CACHE_DIR/kitty-colors.conf" >/dev/null 2>&1 || true
    done
else
    magick -define jpeg:size=1280x720 "$WALLPAPER" -resize "640x360>" -resize 10% -blur 0x2 -resize 1000% "$CACHE_DIR/blurred_wallpaper.jpg" &
    PID_BLUR=$!

    SKIP_RELOAD=1 "$HOME/.local/bin/changetheme.sh" "$WALLPAPER" &
    PID_THEME=$!

    wait $PID_BLUR
    wait $PID_THEME

    cp "$CACHE_DIR/blurred_wallpaper.jpg" "$ENTRY.jpg"
    cp "$CACHE_DIR/colors.css" "$ENTRY.css"
fi

# swaybg is nix-wrapped, so its /proc comm is ".swaybg-wrapped" — pkill -x
# against the literal name never matches and old instances pile up forever.
pkill -f 'swaybg -i' 2>/dev/null
swaybg -i "$CACHE_DIR/blurred_wallpaper.jpg" -m fill </dev/null >/dev/null 2>&1 &

pkill -SIGUSR1 zsh
pkill -SIGUSR1 nvim
dconf write /org/gnome/desktop/interface/color-scheme "'$([[ "$THEME_MODE" == "light" ]] && echo default || echo prefer-dark)'" 2>/dev/null || true
