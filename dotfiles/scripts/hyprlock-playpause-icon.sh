#!/usr/bin/env bash

player=$(~/.local/bin/hyprlock-active-player.sh)
status=$(playerctl -p "$player" status 2>/dev/null)
if [ "$status" = "Playing" ]; then
    echo "󰏤"
else
    echo "󰐊"
fi
