#!/bin/bash

WORKSPACE_ID="$1"

normalize_workspace_id() {
  printf "%s" "$1" | tr '[:lower:]' '[:upper:]'
}

current_workspace() {
  if [ -n "${FOCUSED_WORKSPACE:-}" ]; then
    normalize_workspace_id "$FOCUSED_WORKSPACE"
    return
  fi

  aerospace list-workspaces --focused 2>/dev/null | head -n 1 | tr '[:lower:]' '[:upper:]'
}

workspace_icons() {
  local workspace="$1"
  local icon_strip=" "
  local apps app app_icon

  apps=$(aerospace list-windows --workspace "$workspace" --json 2>/dev/null | jq -r '.[].["app-name"]' 2>/dev/null)

  if [ -z "$apps" ]; then
    return
  fi

  while IFS= read -r app; do
    [ -z "$app" ] && continue
    app_icon="$("$HOME/.config/sketchybar/plugins/icon_map.sh" "$app")"
    if [ -z "$app_icon" ]; then
      icon_strip+="$app  "
    else
      icon_strip+="$app_icon  "
    fi
  done <<< "$apps"

  printf "%s" "$icon_strip"
}

update() {
  source "$HOME/.config/sketchybar/colors.sh"

  local selected="off"
  local label_color="$MAGENTA"
  local icons
  local focused_workspace

  focused_workspace="$(current_workspace)"
  if [ "$(normalize_workspace_id "$WORKSPACE_ID")" = "$focused_workspace" ]; then
    selected="on"
    label_color="$GREEN"
  fi

  icons="$(workspace_icons "$WORKSPACE_ID")"
  if [ -n "$icons" ]; then
    sketchybar --animate tanh 20 --set "$NAME" \
      icon.highlight="$selected" \
      label="$icons" \
      label.drawing=on \
      label.color="$label_color"
  else
    sketchybar --animate tanh 20 --set "$NAME" \
      icon.highlight="$selected" \
      label="" \
      label.drawing=off
  fi
}

mouse_clicked() {
  aerospace workspace "$WORKSPACE_ID" 2>/dev/null || true
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  *) update
  ;;
esac
