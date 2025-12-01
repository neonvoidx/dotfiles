#!/bin/bash

# Get workspace ID from argument
WORKSPACE_ID="$1"

update() {
  # Get current workspace from aerospace
  CURRENT_WORKSPACE=$(aerospace list-workspaces --focused 2>/dev/null)

  WIDTH="dynamic"
  SELECTED="false"

  if [ "$WORKSPACE_ID" = "$CURRENT_WORKSPACE" ]; then
    SELECTED="true"
    WIDTH="0"
  fi

  sketchybar --animate tanh 20 --set $NAME icon.highlight=$SELECTED label.width=$WIDTH
}

mouse_clicked() {
  aerospace workspace "$WORKSPACE_ID"
}

show_apps() {
  # Get list of windows in this workspace with window IDs
  WINDOWS=$(aerospace list-windows --workspace "$WORKSPACE_ID" --format "%{window-id}|%{app-name}" 2>/dev/null | sort -t'|' -k2)

  # Clear existing popup items
  sketchybar --remove '/space\.'"$WORKSPACE_ID"'\.app\..*/'

  if [ -z "$WINDOWS" ]; then
    # No apps, show empty message
    sketchybar --add item space."$WORKSPACE_ID".app.empty popup.space."$WORKSPACE_ID" \
               --set space."$WORKSPACE_ID".app.empty \
                     label="No apps" \
                     icon.drawing=off \
                     label.padding_left=10 \
                     label.padding_right=10
  else
    # Add each window to popup
    INDEX=0
    while IFS='|' read -r window_id app_name; do
      if [ -n "$window_id" ] && [ -n "$app_name" ]; then
        # Create click script to focus this window
        CLICK_SCRIPT="aerospace focus --window-id $window_id; sketchybar --set space.$WORKSPACE_ID popup.drawing=off"

        sketchybar --add item space."$WORKSPACE_ID".app."$INDEX" popup.space."$WORKSPACE_ID" \
                   --set space."$WORKSPACE_ID".app."$INDEX" \
                         label="$app_name" \
                         icon.drawing=off \
                         label.padding_left=10 \
                         label.padding_right=10 \
                         click_script="$CLICK_SCRIPT" \
                   --subscribe space."$WORKSPACE_ID".app."$INDEX" mouse.clicked
        INDEX=$((INDEX + 1))
      fi
    done <<< "$WINDOWS"
  fi

  # Show popup
  sketchybar --set space."$WORKSPACE_ID" popup.drawing=on
}

hide_apps() {
  sketchybar --set space."$WORKSPACE_ID" popup.drawing=off
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  # "mouse.entered") show_apps
  # ;;
  # "mouse.exited"|"mouse.exited.global") hide_apps
  # ;;
  *) update
  ;;
esac
