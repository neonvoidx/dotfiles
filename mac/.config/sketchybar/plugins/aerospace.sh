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

update_focus_colors() {
  source "$HOME/.config/sketchybar/colors.sh"
  
  # Get focused window info
  FOCUSED_JSON=$(aerospace list-windows --focused --json 2>/dev/null)
  FOCUSED_APP=$(echo "$FOCUSED_JSON" | jq -r '.[0].["app-name"]' 2>/dev/null)
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
  
  # Get all workspaces that have windows
  WORKSPACES=$(aerospace list-workspaces --all 2>/dev/null)
  
  # Build a single sketchybar command with all color updates
  args=()
  
  while IFS= read -r workspace; do
    [ -z "$workspace" ] && continue
    workspace_upper=$(echo "$workspace" | tr '[:lower:]' '[:upper:]')
    
    # Get apps in this workspace (deduplicated and sorted)
    apps=$(aerospace list-windows --workspace "$workspace" --json 2>/dev/null | jq -r '.[].["app-name"]' 2>/dev/null | sort -u)
    
    app_index=0
    if [ -n "$apps" ]; then
      while IFS= read -r app; do
        [ -z "$app" ] && continue
        
        # Determine color based on focus
        if [ "$workspace" = "$FOCUSED_WORKSPACE" ] && [ "$app" = "$FOCUSED_APP" ]; then
          APP_COLOR=$GREEN
        else
          APP_COLOR=$GREEN_DIM
        fi
        
        ITEM_NAME="space.${workspace_upper}.app.${app_index}"
        args+=(--set "$ITEM_NAME" label.color="$APP_COLOR")
        
        app_index=$((app_index + 1))
      done <<< "$apps"
    fi
  done <<< "$WORKSPACES"
  
  # Execute all color updates in a single command
  [ ${#args[@]} -gt 0 ] && sketchybar -m "${args[@]}" 2>/dev/null
}

windows_on_spaces() {
  source "$HOME/.config/sketchybar/colors.sh"
  
  # Get focused window info
  FOCUSED_JSON=$(aerospace list-windows --focused --json 2>/dev/null)
  FOCUSED_APP=$(echo "$FOCUSED_JSON" | jq -r '.[0].["app-name"]' 2>/dev/null)
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)
  
  # Get all workspaces that have windows
  WORKSPACES=$(aerospace list-workspaces --all 2>/dev/null)

  while IFS= read -r workspace; do
    [ -z "$workspace" ] && continue
    
    # Convert workspace to uppercase to match space item names in sketchybar
    workspace_upper=$(echo "$workspace" | tr '[:lower:]' '[:upper:]')
    
    # Remove existing app icons for this workspace
    sketchybar --remove "/space\.${workspace_upper}\.app\..*/" 2>/dev/null
    
    # Get apps in this workspace (deduplicated and sorted)
    apps=$(aerospace list-windows --workspace "$workspace" --json 2>/dev/null | jq -r '.[].["app-name"]' 2>/dev/null | sort -u)
    
    # Determine if this is the focused workspace
    IS_FOCUSED_WORKSPACE="false"
    if [ "$workspace" = "$FOCUSED_WORKSPACE" ]; then
      IS_FOCUSED_WORKSPACE="true"
    fi
    
    # Create individual items for each app icon
    app_index=0
    PREV_ITEM="space.${workspace_upper}"
    
    if [ -n "$apps" ]; then
      while IFS= read -r app; do
        [ -z "$app" ] && continue
        app_icon=$($HOME/.config/sketchybar/plugins/icon_map.sh "$app")
        
        # Determine color based on focus
        if [ "$IS_FOCUSED_WORKSPACE" = "true" ] && [ "$app" = "$FOCUSED_APP" ]; then
          APP_COLOR=$GREEN
        else
          APP_COLOR=$GREEN_DIM
        fi
        
        ITEM_NAME="space.${workspace_upper}.app.${app_index}"
        
        # Add app icon item
        sketchybar --add item $ITEM_NAME left \
                   --set $ITEM_NAME \
                         label="$app_icon" \
                         label.font="sketchybar-app-font:Regular:16.0" \
                         label.color=$APP_COLOR \
                         label.padding_left=2 \
                         label.padding_right=2 \
                         icon.drawing=off \
                         background.drawing=off \
                   --move $ITEM_NAME after $PREV_ITEM 2>/dev/null
        
        PREV_ITEM=$ITEM_NAME
        app_index=$((app_index + 1))
      done <<< "$apps"
    fi
    
    # Hide the original label on the space item since we're using individual items
    sketchybar --set space.$workspace_upper label.drawing=off 2>/dev/null
  done <<< "$WORKSPACES"
  
  # Update the bracket to include all space items and app items
  sketchybar --remove spaces 2>/dev/null
  sketchybar --add bracket spaces '/space\..*/' \
             --set spaces \
                   background.color=0xff323449 \
                   background.border_color=0xff323449 \
                   background.border_width=2 \
                   background.drawing=on 2>/dev/null
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
  "window_focus"|"front_app_switched"|"aerospace_workspace_change") 
    window_state
    update_focus_colors
  ;;
  "windows_on_spaces"|"aerospace_windows_change") windows_on_spaces
  ;;
esac
