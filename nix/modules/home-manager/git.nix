{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.git.enable = true;

  # Symlink git configs from dotfiles
  home.file.".gitconfig" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.gitconfig";
  };

  home.file.".gitconfig.local" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/linux/.gitconfig.local";
  };
}
