#!/usr/bin/env bash

cava_config="$HOME/.config/cava/config_waybar"

dict=("⣀" "⣄" "⣤" "⣦" "⣶" "⣷" "⣾" "⣿")

cava -p "$cava_config" | while read -r line; do
    line="${line%;}"
    out=""
    IFS=';' read -ra values <<< "$line"
    for val in "${values[@]}"; do
        out+="${dict[val]}"
    done
    echo "$out"
done
