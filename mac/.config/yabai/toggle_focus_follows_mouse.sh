#!/usr/bin/env sh

app=$(yabai -m query --windows --window 2>/dev/null | jq -r '.app // empty')

if [ "$app" = "zoom.us" ]; then
  yabai -m config focus_follows_mouse off
else
  yabai -m config focus_follows_mouse autofocus
fi
