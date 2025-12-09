#!/bin/bash
INTERNAL_MONITOR="DP-2"
EXTERNAL_MONITOR="DP-3"
WORKSPACES_TO_MOVE=(1 2 4 5 6 7 8 9 10 11)

move_all_workspaces_to_monitor() {
  # Get the list of existing workspace IDs
  existing_workspaces=$(hyprctl workspaces -j | jq '.[].id')

  for workspace in "${WORKSPACES_TO_MOVE[@]}"; do
    if echo "$existing_workspaces" | grep -q -w "$workspace"; then
      hyprctl dispatch moveworkspacetomonitor "$workspace" "$1"
    fi
  done
}

disable_monitor() {
  hyprctl keyword monitor "DP-2, disable"
}

enable_monitor() {
  hyprctl keyword monitor "DP-2,3440x1440@143.92,4880x1582,1.0,bitdepth,10, cm, hdredid, sdrbrightness, 1.3, sdrsaturation, 0.93, vrr, 1"
}

if [ "$1" = "1" ]; then
  enable_monitor
  move_all_workspaces_to_monitor "$INTERNAL_MONITOR"
  hyprctl dispatch moveworkspacetomonitor 2 "$EXTERNAL_MONITOR"
  hyprctl dispatch moveworkspacetomonitor 4 "$EXTERNAL_MONITOR"
  hyprctl dispatch moveworkspacetomonitor 5 "$INTERNAL_MONITOR"
  exit
else
  disable_monitor
  move_all_workspaces_to_monitor "$EXTERNAL_MONITOR"
  exit
fi
