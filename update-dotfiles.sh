#!/usr/bin/env bash

# Script to update git submodules and run GNU Stow
# This script automatically updates all git submodules and then runs stow

set -e  # Exit on error

echo "Updating git submodules..."
if ! git submodule update --init --recursive --remote; then
    echo "✗ Error: Failed to update git submodules" >&2
    exit 1
fi
echo "✓ Successfully updated git submodules"

echo "Running GNU Stow..."
if ! stow --adopt .; then
    echo "✗ Error: Failed to run stow" >&2
    exit 1
fi
echo "✓ Successfully ran stow"

echo "Resetting adopted changes..."
if ! git reset --hard; then
    echo "✗ Error: Failed to reset git changes" >&2
    exit 1
fi
echo "✓ Successfully reset adopted changes"
echo
echo "Dotfiles updated successfully!"
