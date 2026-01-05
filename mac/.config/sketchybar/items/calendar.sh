#!/bin/bash

calendar=(
  icon=cal
  icon.font="$FONT:Regular:13.0"
  icon.padding_right=8
  label.width=160
  label.align=right
  label.font="$FONT:Regular:13.0"
  label.padding_left=8
  padding_left=15
  update_freq=30
  script="$PLUGIN_DIR/calendar.sh"
  click_script="$PLUGIN_DIR/zen.sh"
)

sketchybar --add item calendar right       \
           --set calendar "${calendar[@]}" \
           --subscribe calendar system_woke
