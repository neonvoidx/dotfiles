#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKGLIST="$SCRIPT_DIR/pkglist.txt"

# Check if pkglist.txt exists
if [[ ! -f "$PKGLIST" ]]; then
    echo "Error: pkglist.txt not found at $PKGLIST"
    exit 1
fi

# Check if paru is installed
if ! command -v paru &> /dev/null; then
    echo "Error: paru is not installed"
    exit 1
fi

echo "Installing packages from $PKGLIST..."

# install chaotic aur
sudo ./chaotic.sh
# Read packages and install with paru
# --noconfirm: skip confirmations
# --needed: skip already installed packages
# --ask=4: skip packages that require removing other packages
paru -S --noconfirm --needed --ask=4 - < "$PKGLIST"

echo "Installation complete!"
