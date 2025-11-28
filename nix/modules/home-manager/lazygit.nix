{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Symlink lazygit config from dotfiles
  xdg.configFile."lazygit" = {
    source = "${dotfilesPath}/common/.config/lazygit";
    recursive = true;
  };
}
