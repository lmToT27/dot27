#!/usr/bin/env bash

players=$(playerctl -l 2>/dev/null)

for p in $players; do
    if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ]; then
        echo "$p"
        exit 0
    fi
done

for p in $players; do
    if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Paused" ]; then
        echo "$p"
        exit 0
    fi
done

echo "$players" | head -1
