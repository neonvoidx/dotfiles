#!/bin/bash

# Get all non-empty workspaces
NON_EMPTY_WORKSPACES=$(aerospace list-workspaces --monitor all --empty no 2>/dev/null | tr '[:upper:]' '[:lower:]')

# Get currently focused workspace
# Use environment variable if available (passed by aerospace), otherwise query
if [ -n "$FOCUSED_WORKSPACE" ]; then
  FOCUSED_WORKSPACE="$(printf "%s" "$FOCUSED_WORKSPACE" | tr '[:upper:]' '[:lower:]')"
else
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null | tr '[:upper:]' '[:lower:]')
fi

# All possible workspaces we created
ALL_WORKSPACES=("1" "2" "3" "4" "5" "6" "7" "8" "9" "s")

# Update visibility and highlight for each workspace
for workspace in "${ALL_WORKSPACES[@]}"; do
  # Convert workspace to lowercase for comparison with aerospace output
  workspace_lower=$(echo "$workspace" | tr '[:upper:]' '[:lower:]')
  item_id=$(echo "$workspace" | tr '[:lower:]' '[:upper:]')
  
  if echo "$NON_EMPTY_WORKSPACES" | grep -q "^${workspace_lower}$" || [ "$workspace_lower" = "$FOCUSED_WORKSPACE" ]; then
    # Workspace has windows OR is currently focused, show it
    sketchybar --set space.$item_id drawing=on

    # Update highlight state directly
    if [ "$workspace_lower" = "$FOCUSED_WORKSPACE" ]; then
      sketchybar --set space.$item_id icon.highlight=on
    else
      sketchybar --set space.$item_id icon.highlight=off
    fi
  else
    # Workspace is empty and not focused, hide it
    sketchybar --set space.$item_id drawing=off icon.highlight=off
  fi
done
