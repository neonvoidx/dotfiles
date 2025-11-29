#!/bin/bash

# Generic media control plugin using nowplaying-cli
# Works with Spotify, Apple Music, YouTube, etc.

play_pause() {
  nowplaying-cli togglePlayPause
}

next() {
  nowplaying-cli next
}

back() {
  nowplaying-cli previous
}

update() {
  # Always show media controls - they'll work if media is available
  TRACK=$(nowplaying-cli get title 2>/dev/null)
  ARTIST=$(nowplaying-cli get artist 2>/dev/null)
  APP=$(nowplaying-cli get app 2>/dev/null)
  ARTWORK=$(nowplaying-cli get artworkPath 2>/dev/null)

  # Check if we have any metadata
  if [ -n "$TRACK" ] && [ "$TRACK" != "null" ]; then
    # We have metadata, show everything
    TRACK_SHORT=$(echo "$TRACK" | sed 's/\(.\{30\}\).*/\1.../')
    ARTIST_SHORT=$(echo "$ARTIST" | sed 's/\(.\{30\}\).*/\1.../')

    args=(
      --set media.title label="$TRACK_SHORT"
      --set media.artist label="$ARTIST_SHORT"
      --set media.app label="$APP"
      --set media.play icon=󰏤
      --set media.anchor drawing=on
    )

    # Set artwork if available
    if [ -n "$ARTWORK" ] && [ "$ARTWORK" != "null" ] && [ -f "$ARTWORK" ]; then
      args+=(--set media.cover background.image="$ARTWORK")
    fi
  else
    # No metadata, just show simple play/pause
    args=(
      --set media.anchor drawing=on
      --set media.play icon=󰐊
      --set media.title label=""
      --set media.artist label=""
      --set media.app label="Media Controls"
    )
  fi

  sketchybar -m "${args[@]}"
}

case "$SENDER" in
  "mouse.clicked")
    case "$NAME" in
      "media.play") play_pause ;;
      "media.next") next ;;
      "media.back") back ;;
    esac
    update
    ;;
  *)
    update
    ;;
esac
