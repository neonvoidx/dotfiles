{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
  };

  # Symlink yazi config from dotfiles
  xdg.configFile."yazi" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.config/yazi";
    recursive = true;
  };
}
