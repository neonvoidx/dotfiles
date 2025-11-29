#!/bin/bash

# Layout codes and names
layouts=("S" "T" "G" "M" "K" "VS" "VT" "CT")
layout_names=("scroller" "tile" "grid" "monocle" "deck" "vertical scroller" "vertical tile" "center tile")

# Temp file to store current index
index_file="~/.local/state/currentmangolayout"

# Read current index or default to 0
if [[ -f "$index_file" ]]; then
  current_index=$(cat "$index_file")
else
  current_index=0
fi

# Calculate next index (cycle)
next_index=$(((current_index + 1) % ${#layouts[@]}))

# Save new index
echo "$next_index" >"$index_file"

# Get layout code and name
layout_code="${layouts[$next_index]}"
layout_name="${layout_names[$next_index]}"

# Notify user
notify-send "Switched to layout: $layout_code ($layout_name)"
