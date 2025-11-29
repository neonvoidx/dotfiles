#!/bin/bash

# Change this line with the souce's name from `wpctl status`
MICROPHONE_SOURCE_NAME="RØDE NT-USB"
MICROPHONE_SOURCE_DEFAULT_VOLUME="1.0"

get_volume_line() {
  wpctl status | grep "$MICROPHONE_SOURCE_NAME" | grep -i vol
}

MICROPHONE_SOURCE_ID=$(get_volume_line | grep -o -E '[0-9]+' | head -1)
VOLUME_LINES_COUNT=$(get_volume_line | grep -c vol)
DUNST_MESSAGES="Source not found, unable to mute/unmute microphone."

if [ "$VOLUME_LINES_COUNT" -eq "1" ]; then

  wpctl set-mute "$MICROPHONE_SOURCE_ID" toggle
  # fixing wpctl not saving volumes anymore
  wpctl set-volume "$MICROPHONE_SOURCE_ID" $MICROPHONE_SOURCE_DEFAULT_VOLUME

  MUTED_LINES_COUNT=$(get_volume_line | grep -c "MUTED")

  if [ "$MUTED_LINES_COUNT" -eq "1" ]; then
    DUNST_MESSAGE="Microphone muted"
  else
    DUNST_MESSAGE="Microphone unmuted"
  fi

  notify-send -a "Microphone" -u low Microphone "${DUNST_MESSAGE}" -t 1000

  exit
fi

notify-send -a "Microphone" -u critical Microphone "${DUNST_MESSAGE}"
