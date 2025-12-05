#!/bin/bash

window_state() {
  source "$HOME/.config/sketchybar/colors.sh"
  source "$HOME/.config/sketchybar/icons.sh"

  # Get focused window info from aerospace
  WINDOW_JSON=$(aerospace list-windows --focused --json 2>/dev/null)
  
  # Check if we got valid output
  if [ -z "$WINDOW_JSON" ] || [ "$WINDOW_JSON" = "[]" ]; then
    sketchybar --set $NAME label.drawing=off icon=$YABAI_GRID icon.color=$ORANGE
    return
  fi

  # Aerospace doesn't have the same window state concepts as yabai (float, stack, zoom)
  # So we'll just show a simple indicator that aerospace is managing windows
  args=(--set $NAME icon=$YABAI_GRID icon.color=$ORANGE label.drawing=off)

  sketchybar -m "${args[@]}"
}

windows_on_spaces() {
  # Get all workspaces
  WORKSPACES=$(aerospace list-workspaces --all 2>/dev/null)

  args=()
  while IFS= read -r workspace; do
    [ -z "$workspace" ] && continue
    
    # Convert workspace to uppercase to match space item names in sketchybar
    workspace_upper=$(echo "$workspace" | tr '[:lower:]' '[:upper:]')
    
    icon_strip=" "
    # Get apps in this workspace
    apps=$(aerospace list-windows --workspace "$workspace" --json 2>/dev/null | jq -r '.[].["app-name"]' 2>/dev/null)
    
    if [ -n "$apps" ]; then
      while IFS= read -r app; do
        [ -z "$app" ] && continue
        icon_strip+=" $($HOME/.config/sketchybar/plugins/icon_map.sh "$app")"
      done <<< "$apps"
    fi
    
    # Add to args array - sketchybar will silently ignore if space doesn't exist
    args+=(--set space.$workspace_upper label="$icon_strip" label.drawing=on)
  done <<< "$WORKSPACES"

  [ ${#args[@]} -gt 0 ] && sketchybar -m "${args[@]}" 2>/dev/null
}

mouse_clicked() {
  # Aerospace doesn't have a simple toggle float command like yabai
  # This would require more complex aerospace commands
  echo "Float toggle not implemented for aerospace"
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  "forced") exit 0
  ;;
  "window_focus") window_state 
  ;;
  "windows_on_spaces"|"aerospace_workspace_change"|"aerospace_windows_change") windows_on_spaces
  ;;
esac
