{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink yazi config directory from dotfiles
  xdg.configFile."yazi" = {
    source = "${dotfilesPath}/common/.config/yazi";
    recursive = true;
  };
}
