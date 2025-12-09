#!/bin/bash
# Toggle monitors not touching for gaming

STATE_FILE="/tmp/hypr-gamescreen-state"
SCREEN_STATE_FILE="/tmp/hypr-screen-state"
MONITORS_DEFAULT="$HOME/.config/hypr/hyprland/monitors/monitors.conf"
MONITORS_NOTOUCH="$HOME/.config/hypr/hyprland/monitors/monitors-notouch.conf"
MONITORS_WORK="$HOME/.config/hypr/hyprland/monitors/monitors-work.conf"
MONITORS_WORK_NOTOUCH="$HOME/.config/hypr/hyprland/monitors/monitors-work-notouch.conf"

# Check screen-toggle state to determine which monitors are active
SCREEN_STATE="both"
if [ -f "$SCREEN_STATE_FILE" ]; then
    SCREEN_STATE=$(cat "$SCREEN_STATE_FILE")
fi

# Check current state (default is OFF = using monitors.conf)
if [ -f "$STATE_FILE" ]; then
    # Currently in gaming mode, switch back to default
    if [ "$SCREEN_STATE" = "both" ]; then
        hyprctl keyword source "$MONITORS_DEFAULT"
    else
        hyprctl keyword source "$MONITORS_WORK"
    fi
    rm "$STATE_FILE"
    notify-send "Monitor Layout" "Switched to default (touching)" -t 2000
else
    # Currently in default mode, switch to gaming
    if [ "$SCREEN_STATE" = "both" ]; then
        hyprctl keyword source "$MONITORS_NOTOUCH"
    else
        hyprctl keyword source "$MONITORS_WORK_NOTOUCH"
    fi
    touch "$STATE_FILE"
    notify-send "Monitor Layout" "Switched to gaming (not touching)" -t 2000
fi
