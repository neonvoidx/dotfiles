#!/bin/bash

# List all explicitly and implicitly installed packages
pacman -Qe | awk '{print $1}' >/tmp/pacman_explicit.txt
pacman -Qm | awk '{print $1}' >/tmp/pacman_foreign.txt
pacman -Q | awk '{print $1}' >/tmp/pacman_all.txt

# Show all installed packages (including foreign), sorted and deduped
comm -23 <(sort /tmp/pacman_all.txt) <(sort /tmp/pacman_foreign.txt) >/tmp/pacman_native.txt
cat /tmp/pacman_native.txt /tmp/pacman_foreign.txt | sort | uniq >/tmp/pacman_installed.txt

# Use fzf to interactively select a package and preview its dependencies
fzf --prompt="Pacman Packages > " \
  --preview="p=\$(awk '{print \$1}' <<< '{}'); echo -e \"Dependencies for \$p:\"; pactree -l \$p" \
  </tmp/pacman_installed.txt
