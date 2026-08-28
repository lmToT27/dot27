#!/usr/bin/env bash
# Usage:
#   osd-control.sh vol up|down|mute
#   osd-control.sh bri up|down
#
# Adjusts the hardware, then tells the shell to flash the OSD pill.
# No parsing here: OsdWindow.qml reads the fresh volume/brightness straight
# from AudioService/BrightnessService (Pipewire + sysfs, already reactive),
# so this script has nothing to compute — the IPC call just says "show".

case "$1" in
    vol)
        case "$2" in
            up)   wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
            down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
            mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
        esac
        quickshell ipc call -- osd show volume
        ;;

    bri)
        case "$2" in
            up)   brightnessctl -q s 5%+ ;;
            down) brightnessctl -q s 5%- ;;
        esac
        quickshell ipc call -- osd show brightness
        ;;
esac
