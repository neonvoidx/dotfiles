#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"
source "$HOME/.config/sketchybar/icons.sh"

PEON_BIN="${PEON_BIN:-$(command -v peon 2>/dev/null)}"

set_active() {
  sketchybar --set "$NAME" icon="$AI_ROBOT_LOVE" icon.color="$BLUE" label="AI" label.color="$BLUE"
}

set_paused() {
  sketchybar --set "$NAME" icon="$AI_ROBOT_OFF" icon.color="$GREY" label="AI" label.color="$GREY"
}

state() {
  [ -n "$PEON_BIN" ] || return 1

  case "$("$PEON_BIN" status 2>/dev/null | head -n 1)" in
    *active*|*enabled*) echo active ;;
    *paused*|*DISABLED*) echo paused ;;
    *) return 1 ;;
  esac
}

refresh() {
  case "$(state)" in
    active) set_active ;;
    paused) set_paused ;;
    *) sketchybar --set "$NAME" icon="$AI_ROBOT_OFF" icon.color="$RED" label="AI?" label.color="$RED" ;;
  esac
}

if [ "$SENDER" = "mouse.clicked" ]; then
  case "$(state)" in
    active) "$PEON_BIN" pause >/dev/null 2>&1 && set_paused || refresh ;;
    paused) "$PEON_BIN" resume >/dev/null 2>&1 && set_active || refresh ;;
    *) refresh ;;
  esac
else
  refresh
fi
