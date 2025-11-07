#!/bin/bash

# Check if wlogout is already running
if pgrep -x "wlogout" >/dev/null; then
  pkill wlogout
else
  wlogout --protocol layer-shell
fi
