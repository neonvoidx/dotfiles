{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.kitty.enable = true;

  # Symlink kitty config from dotfiles
  xdg.configFile."kitty" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.config/kitty";
    recursive = true;
  };
}
