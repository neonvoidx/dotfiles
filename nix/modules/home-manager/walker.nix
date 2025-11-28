{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink walker config from dotfiles
  xdg.configFile."walker" = {
    source = "${dotfilesPath}/linux/.config/walker";
    recursive = true;
  };
}
