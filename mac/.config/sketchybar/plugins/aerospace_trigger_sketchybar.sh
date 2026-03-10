#!/bin/bash

# AeroSpace callback helper
#
# Call this from AeroSpace callbacks to trigger SketchyBar custom events.
# Example:
#   ~/.config/sketchybar/plugins/aerospace_trigger_sketchybar.sh aerospace_windows_change 1

EVENT_NAME="$1"
FOCUSED_WORKSPACE="$2"

if [ -z "$EVENT_NAME" ]; then
  exit 0
fi

command -v sketchybar >/dev/null 2>&1 || exit 0

if [ -n "$FOCUSED_WORKSPACE" ]; then
  sketchybar --trigger "$EVENT_NAME" FOCUSED_WORKSPACE="$FOCUSED_WORKSPACE"
else
  sketchybar --trigger "$EVENT_NAME"
fi
