#!/usr/bin/env bash

# Script to update git submodules and run GNU Stow
# This script automatically updates all git submodules and then runs stow

set -e  # Exit on error

echo "Updating git submodules..."
if git submodule update --init --recursive --remote; then
    echo "✓ Successfully updated git submodules"
    
    echo "Running GNU Stow..."
    if stow .; then
        echo "✓ Successfully ran stow"
        echo ""
        echo "Dotfiles updated successfully!"
    else
        echo "✗ Error: Failed to run stow" >&2
        exit 1
    fi
else
    echo "✗ Error: Failed to update git submodules" >&2
    exit 1
fi
