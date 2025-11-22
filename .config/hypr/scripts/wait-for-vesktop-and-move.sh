#!/bin/bash

# EVENT>>DATA
windowopened() {
  # openwindow>>WINDOWADDRESS,WORKSPACENAME,WINDOWCLASS,WINDOWTITLE
  data="${1#openwindow>>}"
  IFS=',' read -r _ _ windowclass _ <<<"$data"
  if [ "$windowclass" = "vesktop" ]; then
    hyprctl dispatch focuswindow class:vesktop
    hyprctl dispatch movewindow u
    exit 0
  fi
}

handle() {
  case $1 in
  openwindow*) windowopened "$1" ;;
  esac
}

socat -U - UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do handle "$line"; done
