#!/bin/bash

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Read pkglist2.txt and check each package
while IFS= read -r line; do
    # Skip empty lines
    [[ -z "$line" ]] && continue
    
    # Remove leading numbers and dots (e.g., "1. packagename" -> "packagename")
    package=$(echo "$line" | sed 's/^[0-9]*\.\s*//')
    
    # Skip if package name is empty after processing
    [[ -z "$package" ]] && continue
    
    # Check if package is installed
    if ! paru -Qi "$package" &>/dev/null; then
        echo -e "${RED}${package}${NC}"
    fi
done < pkglist2.txt
