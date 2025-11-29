#!/bin/bash
title=$(playerctl metadata | grep 'spotify xesam:title' | awk '{$1=$2=""; print $0}')
artist=$(playerctl metadata | grep 'spotify xesam:artist' | awk '{$1=$2=""; print $0}')
album=$(playerctl metadata | grep 'spotify xesam:album ' | awk '{$1=$2=""; print $0}')
status=$(playerctl status)
spotify=" "

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 {title|artist|album|status}"
  exit 1
fi

case "$1" in
title)
  echo "$title" | perl -pe '1 while s/\([^()]*\)//g' | awk '{$1=$1; print}' | tr -d '\n'
  ;;
artist)
  echo "$artist" | perl -pe '1 while s/\([^()]*\)//g' | awk '{$1=$1; print}' | tr -d '\n'
  ;;
album)
  echo "$album" | perl -pe '1 while s/\([^()]*\)//g' | awk '{$1=$1; print}' | tr -d '\n'
  ;;
status)
  echo "$status" | awk '{$1=$1; print}' | tr -d '\n'
  ;;
*)
  echo "Invalid argument: $1"
  echo "Usage: $0 {title|artist|album|status}"
  exit 1
  ;;
esac
