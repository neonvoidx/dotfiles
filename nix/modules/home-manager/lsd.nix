{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink lsd config directory from dotfiles
  xdg.configFile."lsd" = {
    source = "${dotfilesPath}/common/.config/lsd";
    recursive = true;
  };
}
