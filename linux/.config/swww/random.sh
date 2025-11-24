#!/bin/bash

if [[ $# -lt 1 ]] || [[ ! -d $1 ]]; then
  echo "Usage:
	$0 <dir containing images> <monitor>"
  echo "User swww query | grep -Po \"^[^:]+\" to find monitor"
  exit 1
fi

# Edit below to control the images transition
export SWWW_TRANSITION_FPS=60
export SWWW_TRANSITION_STEP=2

# This controls (in seconds) when to switch to the next image
INTERVAL=120

while true; do
  find "$1" -maxdepth 1 -type f -exec file {} \; | awk -F: '{ if ($2 ~/[Ii]mage|EPS/) print $1}' |
    while read -r img; do
      echo "$((RANDOM % 1000)):$img"
    done |
    sort -n | cut -d':' -f2- |
    while read -r img; do
      swww img -o "$2" "$img" --transition-type wipe --transition-angle 45
      sleep $INTERVAL
    done
done
