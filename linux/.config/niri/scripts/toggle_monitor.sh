#!/bin/bash
main=("games" "main")
top=("browser" "communication")
# Turn on
if [ "$1" == "1" ]; then
  niri msg output DP-2 on
  for name in "${main[@]}"; do
    niri msg action move-workspace-to-monitor --reference "$name" "DP-2"
  done
  for name in "${top[@]}"; do
    niri msg action move-workspace-to-monitor --reference "$name" "DP-3"
  done
  exit 0
# Turn off
elif [ "$1" == "0" ]; then
  for name in "${main[@]}"; do
    niri msg action move-workspace-to-monitor --reference "$name" "DP-3"
  done
  niri msg output DP-2 off
  exit 0
else
  printf "Usage: %s [0 (to turn off main monitor)|1 (to turn on main monitor)].\nMoves all workspaces on monitor\n" "$0"
  exit 1
fi
