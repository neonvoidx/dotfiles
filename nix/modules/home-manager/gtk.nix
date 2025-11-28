{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink GTK config directories from dotfiles
  xdg.configFile = {
    "gtk-2.0" = {
      source = "${dotfilesPath}/linux/.config/gtk-2.0";
      recursive = true;
    };
    "gtk-3.0" = {
      source = "${dotfilesPath}/linux/.config/gtk-3.0";
      recursive = true;
    };
    "gtk-4.0" = {
      source = "${dotfilesPath}/linux/.config/gtk-4.0";
      recursive = true;
    };
  };

  # Enable GTK theming
  gtk.enable = true;

  # Qt theming to match GTK
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };
}
