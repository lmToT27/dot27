#!/usr/bin/env bash

player=$(~/.local/bin/hyprlock-active-player.sh)
playerctl -p "$player" "$1"
