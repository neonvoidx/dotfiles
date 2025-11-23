#!/usr/bin/env bash

# Script to update git submodules and run GNU Stow
# This script automatically updates all git submodules and then runs stow

set -e # Exit on error

echo "Updating git submodules..."
if ! git submodule update --init --recursive --remote; then
  echo "✗ Error: Failed to update git submodules" >&2
  exit 1
fi
echo "✓ Successfully updated git submodules"

echo "Running GNU Stow..."
STOW_OUTPUT=$(stow . 2>&1)
STOW_EXIT=$?
if [ $STOW_EXIT -ne 0 ]; then
  if echo "$STOW_OUTPUT" | grep -qi 'adopt'; then
    echo "stow failed, retrying with --adopt..."
    if ! stow --adopt .; then
      echo "✗ Error: Failed to run stow with --adopt" >&2
      exit 1
    fi
    echo "✓ Successfully ran stow with --adopt"
  else
    echo "✗ Error: Failed to run stow" >&2
    echo "$STOW_OUTPUT" >&2
    exit 1
  fi
else
  echo "✓ Successfully ran stow"
fi

echo "Resetting adopted changes..."
if ! git reset --hard origin/master; then
  echo "✗ Error: Failed to hard reset git changes" >&2
  exit 1
fi
if ! git clean -fd; then
  echo "✗ Error: Failed to clean untracked files" >&2
  exit 1
fi
echo "✓ Successfully reset and cleaned adopted changes"

echo

# If on macOS, stow the 'mac' folder to apply Mac-specific symlinks
if [ "$(uname -s)" = "Darwin" ]; then
  echo "Detected macOS. Running stow on 'mac' folder for Mac-specific dotfiles..."
  if ! stow mac; then
    echo "✗ Error: Failed to run stow on 'mac' folder" >&2
    exit 1
  fi
  echo "✓ Successfully ran stow on 'mac' folder"
fi
echo

echo "Dotfiles updated successfully!"
