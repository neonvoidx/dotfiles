{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Symlink btop config directory from dotfiles
  xdg.configFile."btop" = {
    source = "${dotfilesPath}/common/.config/btop";
    recursive = true;
  };
}
