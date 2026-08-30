#!/usr/bin/env bash

player=$(~/.local/bin/hyprlock-active-player.sh)
status=$(playerctl -p "$player" status 2>/dev/null)
if [ "$status" = "Playing" ] || [ "$status" = "Paused" ]; then
    echo "󰎆 $(playerctl -p "$player" metadata --format '{{title}} • {{artist}}' 2>/dev/null)"
else
    echo "󰝛 No media playing"
fi
