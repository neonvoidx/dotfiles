
#!/bin/bash

cpu_top=(
  label.font="$FONT:Semibold:12"
  label=CPU
  icon.drawing=off
  width=120
  padding_right=15
  scroll_duration=100
)

sketchybar --add item cpu.top right              \
           --set cpu.top "${cpu_top[@]}"         \
                                                 \
