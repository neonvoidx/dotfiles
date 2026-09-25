#!/bin/bash

set -o pipefail
source "$HOME/.config/sketchybar/colors.sh"

# Query current state rather than using a possibly stale callback payload.
# A failed query must leave the last successful render intact.
focused=$(aerospace list-workspaces --focused) || exit 1
[ -n "$focused" ] || exit 1
focused=$(printf '%s' "$focused" | tr '[:upper:]' '[:lower:]')
windows=$(aerospace list-windows --all --format '%{workspace}%{app-name}' --json) || exit 1
if ! printf '%s' "$windows" | jq -e 'type == "array" and all(.[]; (.workspace | type == "string") and (."app-name" | type == "string"))' >/dev/null; then
  echo 'Invalid AeroSpace window snapshot; keeping existing workspace state' >&2
  exit 1
fi

args=()
for workspace in 1 2 3 4 5 6 7 8 9 s; do
  item_id=$(printf '%s' "$workspace" | tr '[:lower:]' '[:upper:]')
  apps=$(printf '%s' "$windows" | jq -r --arg workspace "$workspace" \
    '.[] | select((.workspace | ascii_downcase) == $workspace) | ."app-name"' | LC_ALL=C sort) || exit 1
  icons=""
  while IFS= read -r app; do
    [ -n "$app" ] || continue
    app_icon=$("$HOME/.config/sketchybar/plugins/icon_map.sh" "$app")
    icons+="${app_icon:-$app}  "
  done <<< "$apps"

  selected=off
  color=$MAGENTA
  drawing=off
  label_drawing=off
  if [ "$workspace" = "$focused" ]; then
    selected=on
    color=$GREEN
    drawing=on
  fi
  if [ -n "$icons" ]; then
    drawing=on
    label_drawing=on
    icons=" $icons"
  fi

  args+=(--set "space.$item_id" "drawing=$drawing"
    "icon.highlight=$selected" "label=$icons"
    "label.drawing=$label_drawing" "label.color=$color")
done

# Commit all workspace properties together, without competing animations.
sketchybar "${args[@]}"
