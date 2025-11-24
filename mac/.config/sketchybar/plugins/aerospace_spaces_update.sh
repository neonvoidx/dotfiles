#!/bin/bash

# Get all non-empty workspaces
NON_EMPTY_WORKSPACES=$(aerospace list-workspaces --monitor all --empty no 2>/dev/null)

# Get currently focused workspace
FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)

# All possible workspaces we created
ALL_WORKSPACES=("1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z")

# Update visibility and highlight for each workspace
for workspace in "${ALL_WORKSPACES[@]}"; do
  if echo "$NON_EMPTY_WORKSPACES" | grep -q "^${workspace}$" || [ "$workspace" = "$FOCUSED_WORKSPACE" ]; then
    # Workspace has windows OR is currently focused, show it
    sketchybar --set space.$workspace drawing=on

    # Update highlight state directly
    if [ "$workspace" = "$FOCUSED_WORKSPACE" ]; then
      sketchybar --set space.$workspace icon.highlight=on
    else
      sketchybar --set space.$workspace icon.highlight=off
    fi
  else
    # Workspace is empty and not focused, hide it
    sketchybar --set space.$workspace drawing=off icon.highlight=off
  fi
done
