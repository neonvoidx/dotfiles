#!/bin/bash

sketchybar --add item stats.cpu right \
           --set stats.cpu \
                 label="CPU -%" \
                 label.font="$FONT:Bold:12" \
                 icon.drawing=off \
                 update_freq=5 \
                 script="$PLUGIN_DIR/system_stats.sh" \
           \
           --add item stats.ram right \
           --set stats.ram \
                 label="RAM -%" \
                 label.font="$FONT:Bold:12" \
                 icon.drawing=off \
                 update_freq=5 \
                 script="$PLUGIN_DIR/system_stats.sh"
