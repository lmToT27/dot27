#!/usr/bin/env bash
# Thumbnail cache maintenance for the Quickshell clipboard panel — generates
# a letterboxed PNG per image entry and a cached accent-colored glyph icon
# for text entries, pruning thumbnails whose entry has since left history.
# Called once per panel-open by ClipboardWindow.qml; each step self-skips
# on a cache hit so repeat runs are cheap.

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

# Letterboxed onto a square canvas so every thumbnail matches the glyph
# icon's dimensions. Backgrounded + waited so N pending images (e.g. a
# screenshot tool copying several in a row) don't serialize into N x
# decode-time before returning.
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
