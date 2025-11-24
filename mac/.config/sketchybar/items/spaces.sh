#!/bin/bash

# Aerospace workspaces - customize to match your setup
SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M" "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z")

# Add event for updating workspace visibility
sketchybar --add event aerospace_windows_change

# Create workspace items
for i in "${!SPACE_ICONS[@]}"
do
  sid="${SPACE_ICONS[i]}"

  space=(
    icon="$sid"
    icon.padding_left=10
    icon.padding_right=15
    padding_left=2
    padding_right=2
    label.padding_right=20
    icon.highlight_color=$GREEN
    label.font="sketchybar-app-font:Regular:16.0"
    label.background.height=26
    label.background.drawing=on
    label.background.color=$BACKGROUND_2
    label.background.corner_radius=8
    label.drawing=off
    popup.background.border_width=2
    popup.background.corner_radius=9
    popup.background.border_color=$POPUP_BORDER_COLOR
    popup.background.color=0xff24273a
    popup.blur_radius=0
    popup.background.shadow.drawing=off
    script="$PLUGIN_DIR/space.sh $sid"
  )

  sketchybar --add item space.$sid left    \
             --set space.$sid "${space[@]}" \
             --subscribe space.$sid mouse.clicked \
                                    mouse.entered \
                                    mouse.exited \
                                    mouse.exited.global \
                                    aerospace_workspace_change
done

# Add a hidden item to update workspace visibility
sketchybar --add item space_visibility_updater left \
           --set space_visibility_updater \
                 icon.drawing=off \
                 label.drawing=off \
                 width=0 \
                 script="$PLUGIN_DIR/aerospace_spaces_update.sh" \
           --subscribe space_visibility_updater aerospace_workspace_change aerospace_windows_change

spaces=(
  background.color=$BACKGROUND_1
  background.border_color=$BACKGROUND_2
  background.border_width=2
  background.drawing=on
)

sketchybar --add bracket spaces '/space\..*/' \
           --set spaces "${spaces[@]}"

# Initial update of workspace visibility
$PLUGIN_DIR/aerospace_spaces_update.sh
