{ config, pkgs, lib, inputs, ... }:

{
  # Enable Hyprland via home-manager
  # Config is sourced from dotfiles via dotfiles.nix
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
    systemd.enable = true;
  };
}
