#!/bin/bash

while true; do
  result=$(hyprctl clients -j | jq '.[] | select(.class == "vesktop")')
  if [ -n "$result" ]; then
    sleep 2
    hyprctl dispatch focuswindow class:vesktop
    hyprctl dispatch movewindow u
    hyprctl dispatch resizeactive exact 100% 70%
    exit 0
  fi
  sleep 1

done
