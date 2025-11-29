{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.mangohud.enable = true;

  # Symlink MangoHud config from dotfiles
  xdg.configFile."MangoHud" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/linux/.config/MangoHud";
    recursive = true;
  };
}
