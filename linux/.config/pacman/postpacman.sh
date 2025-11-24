#!/bin/bash

# Rust
rustup default nightly
# bat
bat cache --build

# Hyprland services (if using UWSM)
systemctl --user enable --now hypridle.service
systemctl --user enable --now hyprpolkitagent
