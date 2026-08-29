#!/usr/bin/env bash

status=$(playerctl status 2>/dev/null)
if [ "$status" = "Playing" ]; then
    echo "󰎆 $(playerctl metadata --format '{{title}} • {{artist}}' 2>/dev/null)"
elif [ "$status" = "Paused" ]; then
    echo "󰏤 $(playerctl metadata --format '{{title}} • {{artist}}' 2>/dev/null)"
else
    echo "󰝛 No media playing"
fi
