{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink bat config directory from dotfiles
  xdg.configFile."bat" = {
    source = "${dotfilesPath}/common/.config/bat";
    recursive = true;
  };
}
