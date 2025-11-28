{ config, pkgs, lib, ... }:

{
  # GTK config is sourced from dotfiles via dotfiles.nix
  # Enable GTK theming
  gtk.enable = true;

  # Qt theming to match GTK
  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };
}
