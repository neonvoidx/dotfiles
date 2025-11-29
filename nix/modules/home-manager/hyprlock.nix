{ config, pkgs, lib, ... }:

# Hyprlock config is part of the hypr directory symlink in hyprland.nix
# This module just enables the program
{
  programs.hyprlock.enable = true;
}
