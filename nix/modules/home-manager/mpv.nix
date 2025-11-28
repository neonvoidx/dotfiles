{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Symlink mpv config from dotfiles
  xdg.configFile."mpv" = {
    source = "${dotfilesPath}/common/.config/mpv";
    recursive = true;
  };
}
