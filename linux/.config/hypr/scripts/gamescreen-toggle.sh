#!/bin/bash
# Toggle monitors not touching for gaming

STATE_FILE="/tmp/hypr-gamescreen-state"
MONITORS_DEFAULT="$HOME/.config/hypr/hyprland/monitors.conf"
MONITORS_NOTOUCH="$HOME/.config/hypr/hyprland/monitors-notouch.conf"

# Check current state (default is OFF = using monitors.conf)
if [ -f "$STATE_FILE" ]; then
    # Currently in gaming mode, switch back to default
    hyprctl keyword source "$MONITORS_DEFAULT"
    rm "$STATE_FILE"
    notify-send "Monitor Layout" "Switched to default (touching)" -t 2000
else
    # Currently in default mode, switch to gaming
    hyprctl keyword source "$MONITORS_NOTOUCH"
    touch "$STATE_FILE"
    notify-send "Monitor Layout" "Switched to gaming (not touching)" -t 2000
fi
