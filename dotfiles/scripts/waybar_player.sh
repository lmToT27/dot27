#!/usr/bin/env bash

get_active_player() {
    local players
    players=$(playerctl -l 2>/dev/null)
    
    for p in $players; do
        if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Playing" ]; then
            echo "$p"
            return
        fi
    done
    
    for p in $players; do
        if [ "$(playerctl -p "$p" status 2>/dev/null)" = "Paused" ]; then
            echo "$p"
            return
        fi
    done
}

PLAYER=$(get_active_player)

if [ "$1" = "--play-pause" ]; then
    if [ -n "$PLAYER" ]; then
        playerctl -p "$PLAYER" play-pause
    fi
    exit 0
fi

if [ -z "$PLAYER" ]; then
    echo '{"text": " Nothing playing", "tooltip": "Không có media nào đang phát", "class": "stopped"}'
    exit 0
fi

STATUS=$(playerctl -p "$PLAYER" status 2>/dev/null)
TITLE=$(playerctl -p "$PLAYER" metadata title 2>/dev/null)
ARTIST=$(playerctl -p "$PLAYER" metadata artist 2>/dev/null)
POSITION=$(playerctl -p "$PLAYER" metadata --format "{{duration(position)}}" 2>/dev/null)
LENGTH=$(playerctl -p "$PLAYER" metadata --format "{{duration(mpris:length)}}" 2>/dev/null)

if [ "$STATUS" = "Playing" ]; then
    ICON=" "
elif [ "$STATUS" = "Paused" ]; then
    ICON=""
else
    echo '{"text": " Nothing playing", "tooltip": "Không có media nào đang phát", "class": "stopped"}'
    exit 0
fi

TITLE="${TITLE//&/&amp;}"
TITLE="${TITLE//</&lt;}"
TITLE="${TITLE//>/&gt;}"
ARTIST="${ARTIST//&/&amp;}"
ARTIST="${ARTIST//</&lt;}"
ARTIST="${ARTIST//>/&gt;}"

TEXT="$ICON $TITLE - $ARTIST"
TOOLTIP="$TITLE - $ARTIST 󰔛 $POSITION / $LENGTH"

jq -n --unbuffered --compact-output \
    --arg text "$TEXT" \
    --arg tooltip "$TOOLTIP" \
    --arg class "$STATUS" \
    '{"text": $text, "tooltip": $tooltip, "class": $class}'
