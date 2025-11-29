{ config, pkgs, lib, ... }:

# Hypridle config is part of the hypr directory symlink in hyprland.nix
# This module just enables the service
{
  services.hypridle.enable = true;
}
