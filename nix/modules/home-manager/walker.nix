{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  # Symlink walker config from dotfiles
  xdg.configFile."walker" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/linux/.config/walker";
    recursive = true;
  };
}
