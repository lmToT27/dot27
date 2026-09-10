#!/usr/bin/env bash
# IDs are hidden from the UI; rofi's -format i returns the array index
# instead, which stays valid regardless of search filtering.
# Alt+Delete (not Shift+Delete, which is rofi's builtin kb-delete-entry
# and silently wins the binding) deletes and loops back instead of closing.

CACHE_DIR="$HOME/.cache/cliphist/thumbnails"
mkdir -p "$CACHE_DIR"

ACCENT_HEX=$(cat "$HOME/.cache/theme/prompt_color.txt" 2>/dev/null || echo "#7aa2f7")
TEXT_ICON="$CACHE_DIR/text_icon_${ACCENT_HEX//#/}.png"

# -font needs a file path here, not a family name (no fontconfig delegate).
# fc-match is only resolved on a cache miss - it's a real fork, wasted on
# every open otherwise since the icon is already cached almost all the time.
if [ ! -f "$TEXT_ICON" ]; then
    FONT_FILE=$(fc-match -f '%{file}' "JetBrainsMono Nerd Font")
    magick -size 128x128 -background none -fill "$ACCENT_HEX" \
        -font "$FONT_FILE" -gravity center -pointsize 64 label:"󰈔" "$TEXT_ICON"
fi

while true; do
    mapfile -t history < <(cliphist list)

    declare -A live_id_set=()
    for line in "${history[@]}"; do
        live_id_set["${line%%$'\t'*}"]=1
    done
    for thumb in "$CACHE_DIR"/*.png; do
        [ -e "$thumb" ] || continue
        [[ "$thumb" == "$CACHE_DIR"/text_icon_*.png ]] && continue
        id="${thumb##*/}"; id="${id%.png}"
        [[ -n "${live_id_set[$id]:-}" ]] || rm -f "$thumb"
    done

    # Letterboxed onto a square canvas so every thumbnail matches the
    # glyph icon's dimensions. Backgrounded + waited so N pending images
    # (e.g. a screenshot tool copying several in a row) don't serialize
    # into N x decode-time before the panel ever shows up.
    for line in "${history[@]}"; do
        if [[ "$line" == *"[[ binary data"* ]]; then
            id="${line%%$'\t'*}"
            thumb="$CACHE_DIR/$id.png"
            [ -f "$thumb" ] && continue
            ( cliphist decode <<< "$line" \
                | magick - -resize 128x128 -background none -gravity center -extent 128x128 "png:$thumb" 2>/dev/null ) &
        fi
    done
    wait

    # One awk pass replaces a per-line fork of cut/sed/awk/tr (was 4 forks x
    # every history entry on every open); the trailing while-loop is pure
    # bash builtins (read/printf), so rofi's NUL/icon formatting costs zero
    # extra forks.
    index=$(awk -F'\t' '
        {
            id = $1
            content = $0
            sub(/^[^\t]*\t/, "", content)
            if (content ~ /\[\[ binary data .* \]\]/) {
                raw = content
                sub(/.*\[\[ binary data /, "", raw)
                sub(/ \]\]$/, "", raw)
                n = split(raw, parts, " ")
                info = parts[1] " " parts[2]
                for (i = 3; i <= n; i++) info = info " • " parts[i]
                printf "%s\timg\t%s\n", id, info
            } else {
                clean = content
                gsub(/\n/, " ", clean)
                if (length(clean) > 100) clean = substr(clean, 1, 100)
                printf "%s\ttxt\t%s\n", id, clean
            }
        }
    ' < <(printf '%s\n' "${history[@]}") | while IFS=$'\t' read -r id kind text; do
        if [[ "$kind" == img ]]; then
            printf 'Image (%s)\0icon\x1f%s\n' "$text" "$CACHE_DIR/$id.png"
        else
            printf '%s\0icon\x1f%s\n' "$text" "$TEXT_ICON"
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
