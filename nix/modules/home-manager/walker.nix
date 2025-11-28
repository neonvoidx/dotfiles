{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Symlink walker config from dotfiles
  xdg.configFile."walker" = {
    source = "${dotfilesPath}/linux/.config/walker";
    recursive = true;
  };
}
