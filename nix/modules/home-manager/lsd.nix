{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Symlink lsd config directory from dotfiles
  xdg.configFile."lsd" = {
    source = "${dotfilesPath}/common/.config/lsd";
    recursive = true;
  };
}
