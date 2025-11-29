{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.lsd.enable = true;

  # Symlink lsd config from dotfiles
  xdg.configFile."lsd" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.config/lsd";
    recursive = true;
  };
}
