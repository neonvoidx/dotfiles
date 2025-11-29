#!/bin/bash

# Generic media controls - works with any app
POPUP_SCRIPT="sketchybar -m --set media.anchor popup.drawing=toggle"

media_anchor=(
  script="$PLUGIN_DIR/media.sh"
  click_script="$POPUP_SCRIPT"
  icon=󰝚
  icon.font="$FONT:Regular:20.0"
  icon.width=30
  label.drawing=off
  drawing=off
  update_freq=2
  y_offset=2
)

media_cover=(
  click_script="$POPUP_SCRIPT"
  label.drawing=off
  icon.drawing=off
  padding_left=8
  padding_right=8
  background.image.scale=0.15
  background.image.drawing=on
  background.drawing=on
  background.color=$TRANSPARENT
)

media_title=(
  icon.drawing=off
  padding_left=0
  padding_right=0
  width=0
  label.font="$FONT:Heavy:14.0"
  y_offset=35
)

media_artist=(
  icon.drawing=off
  y_offset=15
  padding_left=0
  padding_right=0
  width=0
  label.font="$FONT:Regular:12.0"
)

media_app=(
  icon.drawing=off
  padding_left=0
  padding_right=0
  y_offset=-5
  width=0
  label.font="$FONT:Light Italic:10.0"
)

media_back=(
  icon=$SPOTIFY_BACK
  icon.width=20
  icon.padding_left=5
  icon.padding_right=5
  icon.color=$WHITE
  label.drawing=off
  script="$PLUGIN_DIR/media.sh"
  y_offset=-45
)

media_play=(
  icon=$SPOTIFY_PLAY_PAUSE
  background.height=40
  background.corner_radius=20
  width=40
  align=center
  background.color=$POPUP_BACKGROUND_COLOR
  background.border_color=$WHITE
  background.border_width=0
  background.drawing=on
  icon.padding_left=4
  icon.padding_right=5
  icon.color=$WHITE
  label.drawing=off
  script="$PLUGIN_DIR/media.sh"
  y_offset=-45
)

media_next=(
  icon=$SPOTIFY_NEXT
  icon.width=20
  icon.padding_left=5
  icon.padding_right=5
  icon.color=$WHITE
  label.drawing=off
  script="$PLUGIN_DIR/media.sh"
  y_offset=-45
)

media_controls=(
  background.color=$GREEN
  background.corner_radius=11
  background.drawing=on
  y_offset=-45
)

sketchybar --add item media.anchor center                      \
           --set media.anchor "${media_anchor[@]}"             \
           --subscribe media.anchor mouse.entered mouse.exited \
                                    mouse.exited.global        \
                                                               \
           --add item media.cover popup.media.anchor           \
           --set media.cover "${media_cover[@]}"               \
                                                               \
           --add item media.title popup.media.anchor           \
           --set media.title "${media_title[@]}"               \
                                                               \
           --add item media.artist popup.media.anchor          \
           --set media.artist "${media_artist[@]}"             \
                                                               \
           --add item media.app popup.media.anchor             \
           --set media.app "${media_app[@]}"                   \
                                                               \
           --add item media.back popup.media.anchor            \
           --set media.back "${media_back[@]}"                 \
           --subscribe media.back mouse.clicked                \
                                                               \
           --add item media.play popup.media.anchor            \
           --set media.play "${media_play[@]}"                 \
           --subscribe media.play mouse.clicked                \
                                                               \
           --add item media.next popup.media.anchor            \
           --set media.next "${media_next[@]}"                 \
           --subscribe media.next mouse.clicked                \
                                                               \
           --add bracket media.controls media.back             \
                                        media.play             \
                                        media.next             \
           --set media.controls "${media_controls[@]}"
