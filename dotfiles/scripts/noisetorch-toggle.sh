#!/usr/bin/env bash

STATE_DIR="$HOME/.cache/noisetorch"
PREV_SOURCE_FILE="$STATE_DIR/prev-source"
mkdir -p "$STATE_DIR"

is_active() {
    pw-dump 2>/dev/null | jq -e '
        any(.[]; .type == "PipeWire:Interface:Node"
            and (.info.props["node.description"] // "" | contains("NoiseTorch Microphone")))
    ' >/dev/null
}

default_source_name() {
    pw-dump 2>/dev/null | jq -r '
        .[] | select(.type == "PipeWire:Interface:Metadata" and .props["metadata.name"] == "default")
        | .metadata[]? | select(.key == "default.audio.source") | .value.name
    '
}

node_id_by_name() {
    pw-dump 2>/dev/null | jq -r --arg name "$1" '
        .[] | select(.type == "PipeWire:Interface:Node")
        | select(.info.props["node.name"] == $name) | .id
    ' | head -1
}

noisetorch_source_id() {
    pw-dump 2>/dev/null | jq -r '
        .[] | select(.type == "PipeWire:Interface:Node")
        | select(.info.props["media.class"] == "Audio/Source")
        | select(.info.props["node.description"] // "" | contains("NoiseTorch Microphone"))
        | .id
    ' | head -1
}

if is_active; then
    noisetorch -u

    if [[ -f "$PREV_SOURCE_FILE" ]]; then
        prev_id=$(node_id_by_name "$(<"$PREV_SOURCE_FILE")")
        [[ -n "$prev_id" ]] && wpctl set-default "$prev_id"
        rm -f "$PREV_SOURCE_FILE"
    fi

    notify-send "NoiseTorch" "Noise suppression disabled"
else
    default_source_name > "$PREV_SOURCE_FILE"
    noisetorch -i

    for _ in 1 2 3 4 5 6 7 8 9 10; do
        nt_id=$(noisetorch_source_id)
        [[ -n "$nt_id" ]] && break
        sleep 0.2
    done
    [[ -n "$nt_id" ]] && wpctl set-default "$nt_id"

    notify-send "NoiseTorch" "Noise suppression enabled"
fi
