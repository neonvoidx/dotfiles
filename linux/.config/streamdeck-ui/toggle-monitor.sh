#!/bin/bash

DM="${XDG_CURRENT_DESKTOP}"

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 [1|0]"
  exit 1
fi

ARG="$1"

if [[ "$DM" == "niri" ]]; then
  echo "niri detected"
  if [[ "$ARG" == "1" ]]; then
    notify-send "Enabling monitor (niri)"
    ~/.config/niri/scripts/toggle_monitor.sh 1
  elif [[ "$ARG" == "0" ]]; then
    notify-send "Disabling monitor (niri)"
    ~/.config/niri/scripts/toggle_monitor.sh 0
  else
    echo "Invalid argument: $ARG"
    exit 1
  fi
elif [[ "$DM" == "Hyprland" ]]; then
  echo "Hyprland detected"
  if [[ "$ARG" == "1" ]]; then
    notify-send "Enabling monitor (Hyprland)"
    ~/.config/hypr/scripts/screen-toggle.sh 1
  elif [[ "$ARG" == "0" ]]; then
    notify-send "Disabling monitor (Hyprland)"
    ~/.config/hypr/scripts/screen-toggle.sh 0
  else
    echo "Invalid argument: $ARG"
    exit 1
  fi
else
  echo "Unknown display manager/compositor"
  exit 1
fi
