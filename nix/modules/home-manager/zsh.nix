{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  programs.zsh.enable = true;

  # Symlink .zshrc from dotfiles
  home.file.".zshrc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.zshrc";
  };

  # Enable shell integrations for tools that need them
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.thefuck = {
    enable = true;
    enableZshIntegration = true;
  };
}
