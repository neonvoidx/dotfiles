{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Symlink MangoHud config from dotfiles
  xdg.configFile."MangoHud" = {
    source = "${dotfilesPath}/linux/.config/MangoHud";
    recursive = true;
  };
}
