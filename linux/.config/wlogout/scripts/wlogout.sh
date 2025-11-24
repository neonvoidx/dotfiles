#!/bin/bash

# Check if wlogout is already running
if pgrep -x "wlogout" >/dev/null; then
  pkill wlogout
else
  if [ -n "$1" ]; then
    wlogout --protocol layer-shell --layout "$1"
  else
    wlogout --protocol layer-shell
  fi
fi
