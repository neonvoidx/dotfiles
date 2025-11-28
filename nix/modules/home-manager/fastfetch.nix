{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink fastfetch config directory from dotfiles
  xdg.configFile."fastfetch" = {
    source = "${dotfilesPath}/linux/.config/fastfetch";
    recursive = true;
  };
}
