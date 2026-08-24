#!/usr/bin/env bash

update_title() {
    TITLE=$(niri msg -j focused-window 2>/dev/null | jq -r '.title // empty')
    
    if [ -z "$TITLE" ]; then
        echo '{"text": " Desktop", "class": "empty"}'
    else
        FULL_TITLE="$TITLE"
        DISPLAY_TITLE="$TITLE"
        
        if [ ${#DISPLAY_TITLE} -gt 20 ]; then
            DISPLAY_TITLE="${DISPLAY_TITLE:0:20}..."
        fi
        
        DISPLAY_TITLE="${DISPLAY_TITLE//&/&amp;}"
        DISPLAY_TITLE="${DISPLAY_TITLE//</&lt;}"
        DISPLAY_TITLE="${DISPLAY_TITLE//>/&gt;}"
        
        FULL_TITLE="${FULL_TITLE//&/&amp;}"
        FULL_TITLE="${FULL_TITLE//</&lt;}"
        FULL_TITLE="${FULL_TITLE//>/&gt;}"
        
        jq -n --unbuffered --compact-output \
            --arg text "  $DISPLAY_TITLE" \
            --arg tooltip "$FULL_TITLE" \
            '{"text": $text, "tooltip": $tooltip, "class": "focused"}' 2>/dev/null
    fi
}

update_title

while true; do
    niri msg event-stream 2>/dev/null | while read -r event; do
        if [[ "$event" == *"Window focus changed"* ]]; then
            update_title
        fi
    done
    sleep 1
done
