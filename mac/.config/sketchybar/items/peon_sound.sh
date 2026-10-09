#!/bin/bash

peon_sound=(
  script="$PLUGIN_DIR/peon_sound.sh"
  icon=$AI_ROBOT_LOVE
  icon.color=$BLUE
  icon.font="$FONT:Regular:14.0"
  label="AI"
  label.font="$FONT:Bold:12.0"
  label.color=$BLUE
  padding_left=7
  padding_right=7
  update_freq=60
)

sketchybar --add item peon_sound right \
           --set peon_sound "${peon_sound[@]}" \
           --subscribe peon_sound mouse.clicked \
           --move peon_sound before stats.cpu
