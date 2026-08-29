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

is_inactive() { ! is_active; }

relink_orphans() {
    local target="$1"
    local orphans
    orphans=$(pw-dump 2>/dev/null | jq -r --arg target "$target" '
        ([.[] | select(.type == "PipeWire:Interface:Link") | .info.props["link.input.node"]]) as $linked
        | .[] | select(.type == "PipeWire:Interface:Node")
        | select(.info.props["media.class"] == "Stream/Input/Audio")
        | select(.info.props["node.name"] // "" | startswith("input.filter-chain-") | not)
        | select(([.id] - $linked) | length > 0)
        | .id
    ')
    [[ -z "$orphans" ]] && return

    local out_ports
    mapfile -t out_ports < <(pw-dump 2>/dev/null | jq -r --argjson n "$target" '
        .[] | select(.type == "PipeWire:Interface:Port")
        | select(.info.props["node.id"] == $n and .info.props["port.direction"] == "out") | .id
    ')

    local node in_ports
    for node in $orphans; do
        mapfile -t in_ports < <(pw-dump 2>/dev/null | jq -r --argjson n "$node" '
            .[] | select(.type == "PipeWire:Interface:Port")
            | select(.info.props["node.id"] == $n and .info.props["port.direction"] == "in") | .id
        ')
        local i count=${#in_ports[@]}
        [[ ${#out_ports[@]} -lt $count ]] && count=${#out_ports[@]}
        for ((i = 0; i < count; i++)); do
            pw-link "${out_ports[$i]}" "${in_ports[$i]}" 2>/dev/null
        done
    done
}

noisetorch_retry() {
    local flag="$1" check="$2"
    for _ in 1 2 3 4 5; do
        noisetorch "$flag"
        "$check" && return 0
        sleep 0.3
    done
    "$check"
}

if is_active; then
    if ! noisetorch_retry -u is_inactive; then
        notify-send "NoiseTorch" "Failed to disable noise suppression"
        exit 1
    fi

    if [[ -f "$PREV_SOURCE_FILE" ]]; then
        prev_id=$(node_id_by_name "$(<"$PREV_SOURCE_FILE")")
        if [[ -n "$prev_id" ]]; then
            wpctl set-default "$prev_id"
            relink_orphans "$prev_id"
        fi
        rm -f "$PREV_SOURCE_FILE"
    fi

    notify-send "NoiseTorch" "Noise suppression disabled"
else
    default_source_name > "$PREV_SOURCE_FILE"

    if ! noisetorch_retry -i is_active; then
        rm -f "$PREV_SOURCE_FILE"
        notify-send "NoiseTorch" "Failed to enable noise suppression"
        exit 1
    fi

    nt_id=$(noisetorch_source_id)
    if [[ -n "$nt_id" ]]; then
        wpctl set-default "$nt_id"
        relink_orphans "$nt_id"
    fi

    notify-send "NoiseTorch" "Noise suppression enabled"
fi
