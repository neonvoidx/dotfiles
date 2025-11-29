{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.lazygit.enable = true;

  # Symlink lazygit config from dotfiles
  xdg.configFile."lazygit" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.config/lazygit";
    recursive = true;
  };
}
