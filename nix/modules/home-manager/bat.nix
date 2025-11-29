{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.bat.enable = true;

  # Symlink bat config from dotfiles
  xdg.configFile."bat" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.config/bat";
    recursive = true;
  };
}
