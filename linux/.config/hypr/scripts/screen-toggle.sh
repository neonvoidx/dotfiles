#!/bin/bash
INTERNAL_MONITOR="DP-2"
EXTERNAL_MONITOR="DP-3"
WORKSPACES_TO_MOVE=(1 2 4 5 6 7 8 9 10 11) # everything but discord/spotify workspace
GAMESCREEN_STATE_FILE="/tmp/hypr-gamescreen-state"
SCREEN_STATE_FILE="/tmp/hypr-screen-state"

move_all_workspaces_to_monitor() {
  # Get the list of existing workspace IDs
  existing_workspaces=$(hyprctl workspaces -j | jq '.[].id')

  for workspace in "${WORKSPACES_TO_MOVE[@]}"; do
    if echo "$existing_workspaces" | grep -q -w "$workspace"; then
      hyprctl dispatch moveworkspacetomonitor "$workspace" "$1"
    fi
  done
}

if [ "$1" = "1" ]; then
  # Enable internal monitor
  if [ -f "$GAMESCREEN_STATE_FILE" ]; then
    hyprctl keyword source "$HOME/.config/hypr/hyprland/monitors-notouch.conf"
  else
    hyprctl keyword source "$HOME/.config/hypr/hyprland/monitors.conf"
  fi
  move_all_workspaces_to_monitor "$INTERNAL_MONITOR"
  hyprctl dispatch moveworkspacetomonitor 2 "$EXTERNAL_MONITOR"
  hyprctl dispatch moveworkspacetomonitor 4 "$EXTERNAL_MONITOR"
  hyprctl dispatch moveworkspacetomonitor 5 "$INTERNAL_MONITOR"
  echo "both" > "$SCREEN_STATE_FILE"
  exit
else
  # Disable internal monitor
  if [ -f "$GAMESCREEN_STATE_FILE" ]; then
    hyprctl keyword source "$HOME/.config/hypr/hyprland/monitors-work-notouch.conf"
  else
    hyprctl keyword source "$HOME/.config/hypr/hyprland/monitors-work.conf"
  fi
  move_all_workspaces_to_monitor "$EXTERNAL_MONITOR"
  echo "external" > "$SCREEN_STATE_FILE"
  exit
fi
