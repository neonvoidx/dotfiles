#!/usr/bin/env bash
FILE="$1"

if command -v identify >/dev/null; then
  # Get width×height and format
  identify -format "Format: %m\nDimensions: %wx%h\nSize: %b\n" "$FILE"
else
  echo "ImageMagick not installed – cannot fetch dimensions."
fi
