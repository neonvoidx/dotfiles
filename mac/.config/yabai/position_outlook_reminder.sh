#!/bin/bash

margin_right=24
margin_bottom=24

window_id=${YABAI_WINDOW_ID:-}

if [ -n "$window_id" ]; then
  window_json=$(yabai -m query --windows --window "$window_id" 2>/dev/null)
else
  window_json=$(yabai -m query --windows | jq -c 'first(.[] | select(.app == "Microsoft Outlook" and (.title | test(".*Reminders?"))))')
fi

if [ -z "$window_json" ] || [ "$window_json" = "null" ]; then
  exit 0
fi

window_app=$(printf '%s' "$window_json" | jq -r '.app')
window_title=$(printf '%s' "$window_json" | jq -r '.title')

if [ "$window_app" != "Microsoft Outlook" ]; then
  exit 0
fi

if ! printf '%s' "$window_title" | grep -Eq 'Reminders?'; then
  exit 0
fi

window_id=$(printf '%s' "$window_json" | jq -r '.id')
window_w=$(printf '%s' "$window_json" | jq -r '.frame.w | floor')
window_h=$(printf '%s' "$window_json" | jq -r '.frame.h | floor')

current_space_json=$(yabai -m query --spaces --space)
display_id=$(printf '%s' "$current_space_json" | jq -r '.display')

display_json=$(yabai -m query --displays --display "$display_id")
display_x=$(printf '%s' "$display_json" | jq -r '.frame.x | floor')
display_y=$(printf '%s' "$display_json" | jq -r '.frame.y | floor')
display_w=$(printf '%s' "$display_json" | jq -r '.frame.w | floor')
display_h=$(printf '%s' "$display_json" | jq -r '.frame.h | floor')

target_x=$((display_x + display_w - window_w - margin_right))
target_y=$((display_y + display_h - window_h - margin_bottom))

yabai -m window "$window_id" --move abs:"$target_x":"$target_y"
