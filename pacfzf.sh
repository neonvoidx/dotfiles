#!/usr/bin/env bash

# Ensure paru and fzf are installed
if ! command -v paru &>/dev/null; then
  echo "paru not found. Please install paru."
  exit 1
fi

if ! command -v fzf &>/dev/null; then
  echo "fzf not found. Please install fzf."
  exit 1
fi

# Prompt for a search query
read -rp "Enter search term for packages: " query

if [ -z "$query" ]; then
  echo "Search term cannot be empty."
  exit 1
fi

echo "Use TAB to multi-select packages. Press ENTER to confirm."

packages=$(paru -Ss "$query" |
  fzf --multi --preview 'paru -Si {1}' --preview-window=up:wrap |
  awk '{print $2}' | cut -d'/' -f2)

if [[ -z "$packages" ]]; then
  echo "No packages selected."
  exit 0
fi

paru -S $packages
