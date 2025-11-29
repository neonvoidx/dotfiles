submap=$(hyprctl submap)
if [ "$submap" = "default" ]; then
  echo "normal"
elif [ "$submap" = "resize" ]; then
  echo "resize"
fi
