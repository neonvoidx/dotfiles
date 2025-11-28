{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository (adjust if needed)
  dotfilesPath = ../../../..;
in
{
  # Symlink kitty config from dotfiles
  xdg.configFile = {
    # Common kitty configs (themes, sessions, etc.)
    "kitty" = {
      source = "${dotfilesPath}/common/.config/kitty";
      recursive = true;
    };
  };

  # Linux-specific kitty config overrides
  home.file.".config/kitty/kitty.conf.local" = {
    source = "${dotfilesPath}/linux/.config/kitty/kitty.conf";
  };
}
