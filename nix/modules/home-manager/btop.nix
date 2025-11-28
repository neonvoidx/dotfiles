{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink btop config directory from dotfiles
  xdg.configFile."btop" = {
    source = "${dotfilesPath}/common/.config/btop";
    recursive = true;
  };
}
