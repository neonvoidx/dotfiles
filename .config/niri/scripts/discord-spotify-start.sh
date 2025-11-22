#!/bin/bash

sleep 5
while true; do
  vesktop_present=$(niri msg -j windows | jq '[.[] | select(.app_id=="vesktop")] | length')
  spotify_present=$(niri msg -j windows | jq '[.[] | select(.app_id=="Spotify")] | length')
  if [[ "$vesktop_present" -eq 1 && "$spotify_present" -eq 1 ]]; then
    break
  fi
  sleep 1
done

# Find vesktop and spotify window ids
vesktopId=$(niri msg -j windows | jq '.[] | select(.app_id=="vesktop") | .id')
spotifyId=$(niri msg -j windows | jq '.[] | select(.app_id=="Spotify") | .id')

# ensure both windows are on workspace 1
niri msg action move-window-to-workspace --window-id "$vesktopId" 1
niri msg action move-window-to-workspace --window-id "$spotifyId" 1

niri msg action focus-monitor HDMI-A-1
niri msg action focus-workspace 1
niri msg action focus-window --id "$spotifyId"
niri msg action consume-window-into-column

# Set window heights
niri msg action set-window-height --id "$vesktopId" 70%
niri msg action focus-window --id "$vesktopId"
niri msg action move-window-up

# refocus monitor 1
niri msg action focus-monitor DP-2
niri msg action focus-workspace 1
