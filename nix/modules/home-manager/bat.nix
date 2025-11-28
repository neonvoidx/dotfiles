{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Symlink bat config directory from dotfiles
  xdg.configFile."bat" = {
    source = "${dotfilesPath}/common/.config/bat";
    recursive = true;
  };
}
