{ config, pkgs, lib, inputs, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
    systemd.enable = true;
  };

  # Symlink hypr config from dotfiles
  xdg.configFile."hypr" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/linux/.config/hypr";
    recursive = true;
  };
}
