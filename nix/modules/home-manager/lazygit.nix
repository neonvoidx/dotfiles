{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink lazygit config from dotfiles
  xdg.configFile."lazygit" = {
    source = "${dotfilesPath}/common/.config/lazygit";
    recursive = true;
  };
}
