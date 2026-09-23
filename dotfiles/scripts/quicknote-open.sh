#!/usr/bin/env bash
# Single-instance guard for the standalone Quick Note app (dotfiles/
# quicknote/main.qml — a plain `qml` process, not through quickshell, so
# it has no Quickshell.Io/IPC to hook into): already running -> focus it;
# not running -> launch. No hide/show toggle — closing is just niri's
# normal Mod+Q close-window, and content survives via Qt.labs.settings.
WIN_ID=$(niri msg -j windows | jq -r '.[] | select(.title=="Quick Note") | .id' | head -1)

if [ -z "$WIN_ID" ]; then
    # setsid fully detaches from this script's process/session so the app
    # keeps running once this script exits — a bare `quicknote &` was
    # getting reaped along with it.
    setsid quicknote &
else
    niri msg action focus-window --id "$WIN_ID"
fi
