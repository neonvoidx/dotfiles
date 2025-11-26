#!/bin/bash

# Interactive package search with FZF and paru
# Multi-select packages and copy to clipboard with wl-copy

# Search only installed packages
paru -Qq | \
fzf --multi \
    --preview 'paru -Qi {} 2>/dev/null | grep -E "(^Name|^Version|^Description|Required By)" || echo "No info found"' \
    --preview-window=right:50%:wrap \
    --prompt="Search packages: " \
    --header="TAB to select multiple | ENTER to confirm" \
    --bind 'tab:toggle+down' \
    --border | \
tr '\n' ' ' | \
wl-copy

# Notify user
if [ $? -eq 0 ]; then
    selected=$(wl-paste)
    if [ -n "$selected" ]; then
        echo "Copied to clipboard: $selected"
    else
        echo "No packages selected"
    fi
fi
