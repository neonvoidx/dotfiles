#!/bin/bash

FRONT_APP_SCRIPT='
WINDOW=$(yabai -m query --windows --window 2>/dev/null)
APP=$(echo "$WINDOW" | jq -r ".app" 2>/dev/null)
TITLE=$(echo "$WINDOW" | jq -r ".title" 2>/dev/null)
[ -z "$APP" ] || [ "$APP" = "null" ] && APP="$INFO"
ICON=$($HOME/.config/sketchybar/plugins/icon_map.sh "$APP")
if [ -n "$TITLE" ] && [ "$TITLE" != "null" ] && [ "$TITLE" != "$APP" ]; then
  LABEL="$APP — $TITLE"
else
  LABEL="$APP"
fi
sketchybar --set $NAME label="$LABEL" icon="$ICON" icon.drawing=on
'

# Detect which window manager is running
if pgrep -x "yabai" > /dev/null; then
  WM="yabai"
  WM_SCRIPT="$PLUGIN_DIR/yabai.sh"
  WM_EVENTS="window_focus windows_on_spaces mouse.clicked"
elif command -v aerospace > /dev/null && pgrep -x "AeroSpace" > /dev/null; then
  WM="aerospace"
  WM_SCRIPT="$PLUGIN_DIR/aerospace.sh"
  # Subscribe to aerospace_workspace_change instead of windows_on_spaces
  WM_EVENTS="window_focus front_app_switched aerospace_workspace_change aerospace_windows_change mouse.clicked"
else
  # Default to yabai script if neither is detected
  WM="yabai"
  WM_SCRIPT="$PLUGIN_DIR/yabai.sh"
  WM_EVENTS="window_focus windows_on_spaces mouse.clicked"
fi

wm_item=(
  script="$WM_SCRIPT"
  icon.font="$FONT:Bold:16.0"
  label.drawing=off
  icon.width=30
  icon=$YABAI_GRID
  icon.color=$ORANGE
  associated_display=active
)

front_app=(
  script="$FRONT_APP_SCRIPT"
  icon.drawing=on
  icon.font="$FONT:Regular:14.0"
  icon.color=$PINK
  icon.padding_right=6
  padding_left=5
  label.color=$PINK
  label.background=$GREY
  label.font="$FONT:Bold:13.0"
  label.max_chars=60
  associated_display=active
)

sketchybar --add event window_focus            \
           --add event windows_on_spaces       \
           --add item front_app center         \
           --set front_app "${front_app[@]}"   \
           --subscribe front_app front_app_switched window_focus title_change

