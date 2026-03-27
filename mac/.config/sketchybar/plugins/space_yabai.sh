#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

update() {
  if [ "$SELECTED" = "true" ]; then
    sketchybar --animate tanh 20 --set $NAME icon.highlight=on
  else
    sketchybar --animate tanh 20 --set $NAME icon.highlight=off
  fi

  # Show app icons for this space (exclude minimized windows)
  icon_strip=" "
  apps=$(yabai -m query --windows --space $SID 2>/dev/null | jq -r '.[].app' 2>/dev/null)
  if [ -n "$apps" ]; then
    while IFS= read -r app; do
      app_icon="$($HOME/.config/sketchybar/plugins/icon_map.sh "$app")"
      if [ -z "$app_icon" ]; then
        icon_strip+="$app  "
      else
        icon_strip+="$app_icon  "
      fi
    done <<< "$apps"
    if [ "$SELECTED" = "true" ]; then
      icon_color=$GREEN
    else
      icon_color=$MAGENTA
    fi
    sketchybar --set $NAME label="$icon_strip" label.drawing=on label.color=$icon_color
  else
    sketchybar --set $NAME label.drawing=off
  fi
}

mouse_clicked() {
  yabai -m space --focus $SID 2>/dev/null || true
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  *) update
  ;;
esac
