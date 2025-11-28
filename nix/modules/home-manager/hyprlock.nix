{ config, pkgs, lib, ... }:

{
  # Hyprlock config is included in the hypr directory symlink from hyprland.nix
  # This module just ensures hyprlock is available
  programs.hyprlock.enable = true;
}
