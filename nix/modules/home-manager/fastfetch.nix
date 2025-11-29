{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.fastfetch.enable = true;

  # Symlink fastfetch config from dotfiles
  xdg.configFile."fastfetch" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/linux/.config/fastfetch";
    recursive = true;
  };
}
