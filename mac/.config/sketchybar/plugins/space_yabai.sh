#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

update() {
  if [ "$SELECTED" = "true" ]; then
    sketchybar --animate tanh 20 --set $NAME icon.highlight=on
  else
    sketchybar --animate tanh 20 --set $NAME icon.highlight=off
  fi

  # Show a dot per open window
  app_count=$(yabai -m query --windows --space $SID 2>/dev/null | jq 'length' 2>/dev/null)
  if [ -n "$app_count" ] && [ "$app_count" -gt 0 ]; then
    dots=$(printf '•%.0s' $(seq 1 "$app_count"))
    if [ "$SELECTED" = "true" ]; then
      dot_color=$GREEN
    else
      dot_color=$MAGENTA
    fi
    sketchybar --set $NAME label="$dots" label.drawing=on label.color=$dot_color
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
