{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.btop.enable = true;

  # Symlink btop config from dotfiles
  xdg.configFile."btop" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.config/btop";
    recursive = true;
  };
}
