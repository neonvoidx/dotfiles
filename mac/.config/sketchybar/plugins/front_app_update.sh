#!/bin/bash

get_app() {
  if [ -n "${INFO:-}" ]; then
    printf "%s" "$INFO"
    return
  fi

  if command -v yabai >/dev/null 2>&1; then
    yabai -m query --windows --window 2>/dev/null | jq -r '.app // empty' 2>/dev/null
    return
  fi

  if command -v aerospace >/dev/null 2>&1; then
    aerospace list-windows --focused --json 2>/dev/null | jq -r '.[0]["app-name"] // empty' 2>/dev/null
    return
  fi

  printf "%s" ""
}

get_title() {
  if command -v yabai >/dev/null 2>&1; then
    yabai -m query --windows --window 2>/dev/null | jq -r '.title // empty' 2>/dev/null
    return
  fi

  if command -v aerospace >/dev/null 2>&1; then
    aerospace list-windows --focused --json 2>/dev/null | jq -r '.[0]["window-title"] // empty' 2>/dev/null
    return
  fi

  printf "%s" ""
}

APP="$(get_app)"
TITLE="$(get_title)"

if [ -z "$APP" ]; then
  sketchybar --set "$NAME" label.drawing=off icon.drawing=off
  exit 0
fi

ICON="$($HOME/.config/sketchybar/plugins/icon_map.sh "$APP")"
if [ -z "$ICON" ]; then
  sketchybar --set "$NAME" label="$APP" icon.drawing=off label.drawing=on
  exit 0
fi

LABEL="$APP"
if [ -n "$TITLE" ] && [ "$TITLE" != "$APP" ]; then
  LABEL="$APP — $TITLE"
fi

sketchybar --set "$NAME" label="$LABEL" icon="$ICON" icon.drawing=on label.drawing=on
