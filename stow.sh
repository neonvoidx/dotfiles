#!/bin/bash
set -e # Exit on error

echo "Updating git submodules..."
if ! git submodule update --init --recursive --remote; then
  echo "✗ Error: Failed to update git submodules" >&2
  exit 1
fi
echo "✓ Successfully updated git submodules"

echo "Running stow for common package..."
stow -v common
echo

if [ "$(uname -s)" = "Darwin" ]; then
  echo "Detected macOS. Running stow on 'mac' folder for Mac-specific dotfiles..."
  stow -v mac
  echo "✓ Successfully ran stow on 'mac' folder"
fi

if [ "$(uname -s)" = "Linux" ]; then
  echo "Detected Linux. Running stow on 'linux' folder..."
  stow -v linux
  echo "✓ Successfully ran stow on 'linux' folder"
fi
echo

echo "Dotfiles updated successfully!"
