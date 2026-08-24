#!/usr/bin/env bash

cava_config="$HOME/.config/cava/config_waybar"

echo "⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀"

stdbuf -oL cava -p "$cava_config" | awk -F';' 'BEGIN {
    split("⣀ ⣄ ⣤ ⣦ ⣶ ⣷ ⣾ ⣿", dict, " ")
}
{
    out = ""
    for (i = 1; i < NF; i++) {
        out = out dict[$i + 1]
    }
    print out
    fflush(stdout)
}'
