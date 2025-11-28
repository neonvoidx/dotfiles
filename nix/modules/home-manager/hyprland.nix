{ config, pkgs, lib, inputs, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Enable Hyprland via home-manager
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
    systemd.enable = true;
  };

  # Symlink hypr config directory from dotfiles
  xdg.configFile."hypr" = {
    source = "${dotfilesPath}/linux/.config/hypr";
    recursive = true;
  };
}
