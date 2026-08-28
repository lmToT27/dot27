#!/usr/bin/env bash
# IDs are hidden from the UI; rofi's -format i returns the array index
# instead, which stays valid regardless of search filtering.
# Alt+Delete (not Shift+Delete, which is rofi's builtin kb-delete-entry
# and silently wins the binding) deletes and loops back instead of closing.

CACHE_DIR="$HOME/.cache/cliphist/thumbnails"
mkdir -p "$CACHE_DIR"

ACCENT_HEX=$(cat "$HOME/.cache/theme/prompt_color.txt" 2>/dev/null || echo "#7aa2f7")

# -font needs a file path here, not a family name (no fontconfig delegate).
# Cached per accent color so a theme change doesn't leave a stale icon.
FONT_FILE=$(fc-match -f '%{file}' "JetBrainsMono Nerd Font")
TEXT_ICON="$CACHE_DIR/text_icon_${ACCENT_HEX//#/}.png"
[ -f "$TEXT_ICON" ] || magick -size 128x128 -background none -fill "$ACCENT_HEX" \
    -font "$FONT_FILE" -gravity center -pointsize 64 label:"󰈔" "$TEXT_ICON"

while true; do
    mapfile -t history < <(cliphist list)

    live_ids=$(printf '%s\n' "${history[@]}" | cut -f1)
    for thumb in "$CACHE_DIR"/*.png; do
        [ -e "$thumb" ] || continue
        [[ "$thumb" == "$CACHE_DIR"/text_icon_*.png ]] && continue
        id=$(basename "$thumb" .png)
        grep -qx "$id" <<< "$live_ids" || rm -f "$thumb"
    done

    # Letterboxed onto a square canvas so every thumbnail matches the
    # glyph icon's dimensions.
    for line in "${history[@]}"; do
        if [[ "$line" == *"[[ binary data"* ]]; then
            id=$(cut -f1 <<< "$line")
            thumb="$CACHE_DIR/$id.png"
            [ -f "$thumb" ] || cliphist decode <<< "$line" \
                | magick - -resize 128x128 -background none -gravity center -extent 128x128 "png:$thumb" 2>/dev/null
        fi
    done

    index=$(for line in "${history[@]}"; do
        id=$(cut -f1 <<< "$line")
        content=$(cut -f2- <<< "$line")

        if [[ "$content" == *"[[ binary data"* ]]; then
            # "85 KiB png 224x298" -> "85 KiB • png • 224x298"
            raw=$(sed -n 's/.*\[\[ binary data \(.*\) \]\]/\1/p' <<< "$content")
            info=$(awk '{ out = $1 " " $2; for (i = 3; i <= NF; i++) out = out " • " $i; print out }' <<< "$raw")
            printf 'Image (%s)\0icon\x1f%s\n' "$info" "$CACHE_DIR/$id.png"
        else
            clean=$(tr '\n' ' ' <<< "$content" | cut -c 1-100)
            printf '%s\0icon\x1f%s\n' "$clean" "$TEXT_ICON"
        fi
    done | rofi -dmenu -show-icons -format "i" -theme "$HOME/.config/rofi/theme.rasi" -p " 󰅍 " -kb-custom-1 "Alt+Delete")

    exit_code=$?

    [ -z "$index" ] && break
    original_line="${history[$index]}"

    if [ "$exit_code" -eq 10 ]; then
        cliphist delete <<< "$original_line"
        notify-send "Clipboard" "Item deleted from history" -u low -t 2000
        continue
    fi

    cliphist decode <<< "$original_line" | wl-copy
    break
done
