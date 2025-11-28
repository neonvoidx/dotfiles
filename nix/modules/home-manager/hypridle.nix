{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Hypridle config is included in the hypr directory symlink from hyprland.nix
  # This module just ensures the service is enabled
  services.hypridle.enable = true;
}
