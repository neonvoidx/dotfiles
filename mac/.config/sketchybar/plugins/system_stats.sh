#!/bin/bash

source "$HOME/.config/sketchybar/colors.sh"

color_for_pct() {
  local pct=$1
  if [ "$pct" -ge 75 ]; then
    echo "$RED"
  elif [ "$pct" -ge 40 ]; then
    echo "$YELLOW"
  else
    echo "$GREEN"
  fi
}

# CPU usage across all cores
CORES=$(sysctl -n hw.logicalcpu)
CPU=$(ps -A -o %cpu | awk -v c="$CORES" '{s+=$1} END {printf "%.0f", s/c}')
[ -z "$CPU" ] && CPU=0

# RAM usage
PAGE=$(vm_stat | head -1 | grep -o '[0-9]*')
USED=$(vm_stat | awk '
  /Pages active/              {gsub(/\./,"",$NF); a=$NF}
  /Pages wired down/          {gsub(/\./,"",$NF); w=$NF}
  /Pages occupied by compressor/ {gsub(/\./,"",$NF); c=$NF}
  END {print a+w+c}
')
TOTAL=$(sysctl -n hw.memsize)
RAM=$(awk -v used="$USED" -v page="$PAGE" -v total="$TOTAL" \
  'BEGIN {printf "%.0f", used*page*100/total}')
[ -z "$RAM" ] && RAM=0

CPU_COLOR=$(color_for_pct "$CPU")
RAM_COLOR=$(color_for_pct "$RAM")

sketchybar --set stats.cpu label="CPU ${CPU}%" label.color="$CPU_COLOR" \
           --set stats.ram label="RAM ${RAM}%" label.color="$RAM_COLOR"
