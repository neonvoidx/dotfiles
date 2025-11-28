{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Symlink yazi config directory from dotfiles
  xdg.configFile."yazi" = {
    source = "${dotfilesPath}/common/.config/yazi";
    recursive = true;
  };
}
