{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.bash.enable = true;

  # Symlink bash configs from dotfiles
  home.file.".bashrc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.bashrc";
  };

  home.file.".bash_profile" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.bash_profile";
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };
}
