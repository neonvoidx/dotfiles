{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Symlink fastfetch config directory from dotfiles
  xdg.configFile."fastfetch" = {
    source = "${dotfilesPath}/linux/.config/fastfetch";
    recursive = true;
  };
}
