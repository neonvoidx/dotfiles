{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.mpv.enable = true;

  # Symlink mpv config from dotfiles
  xdg.configFile."mpv" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.config/mpv";
    recursive = true;
  };
}
