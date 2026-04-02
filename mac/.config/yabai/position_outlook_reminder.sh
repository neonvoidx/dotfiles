#!/bin/bash

margin_right=24
margin_bottom=24

window_json=$(yabai -m query --windows | jq -c 'first(.[] | select(.app == "Microsoft Outlook" and (.title | test(".*Reminders?"))))')

if [ -z "$window_json" ] || [ "$window_json" = "null" ]; then
  exit 0
fi

window_id=$(printf '%s' "$window_json" | jq -r '.id')
display_id=$(printf '%s' "$window_json" | jq -r '.display')
window_w=$(printf '%s' "$window_json" | jq -r '.frame.w | floor')
window_h=$(printf '%s' "$window_json" | jq -r '.frame.h | floor')

display_json=$(yabai -m query --displays --display "$display_id")
display_x=$(printf '%s' "$display_json" | jq -r '.frame.x | floor')
display_y=$(printf '%s' "$display_json" | jq -r '.frame.y | floor')
display_w=$(printf '%s' "$display_json" | jq -r '.frame.w | floor')
display_h=$(printf '%s' "$display_json" | jq -r '.frame.h | floor')

target_x=$((display_x + display_w - window_w - margin_right))
target_y=$((display_y + display_h - window_h - margin_bottom))

yabai -m window "$window_id" --move abs:"$target_x":"$target_y"
