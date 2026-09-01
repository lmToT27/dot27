#!/usr/bin/env bash

CACHE_DIR="$HOME/.cache/theme"
MODE_FILE="$CACHE_DIR/mode"
WALLPAPER_FILE="$CACHE_DIR/current_wallpaper.txt"
mkdir -p "$CACHE_DIR"

CURRENT_MODE=$([[ -f "$MODE_FILE" ]] && cat "$MODE_FILE" || echo "dark")
NEW_MODE=$([[ "$CURRENT_MODE" == "light" ]] && echo "dark" || echo "light")
echo "$NEW_MODE" > "$MODE_FILE"

[[ ! -f "$WALLPAPER_FILE" ]] && exit 0
WALLPAPER=$(<"$WALLPAPER_FILE")
[[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]] && exit 0

THEME_MODE="$NEW_MODE" "$HOME/.local/bin/changetheme.sh" "$WALLPAPER"
