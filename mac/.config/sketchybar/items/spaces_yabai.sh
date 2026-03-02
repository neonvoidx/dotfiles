#!/bin/bash

# Yabai macOS spaces (1-9)
SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9")

for i in "${!SPACE_ICONS[@]}"
do
  sid=$(( $i + 1 ))

  space=(
    space=$sid
    icon="${SPACE_ICONS[i]}"
    icon.padding_left=10
    icon.padding_right=15
    padding_left=2
    padding_right=2
    label.padding_right=20
    icon.highlight_color=$GREEN
    label.font="$FONT:Regular:14.0"
    label.background.height=26
    label.background.drawing=on
    label.background.color=$BACKGROUND_2
    label.background.corner_radius=8
    label.drawing=off
    script="$PLUGIN_DIR/space_yabai.sh"
  )

  sketchybar --add space space.$sid left   \
             --set space.$sid "${space[@]}" \
             --subscribe space.$sid mouse.clicked
done

spaces=(
  background.color=$BACKGROUND_1
  background.border_color=$BACKGROUND_2
  background.border_width=2
  background.drawing=on
)

sketchybar --add bracket spaces '/space\..*/' \
           --set spaces "${spaces[@]}"
