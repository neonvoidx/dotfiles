{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink MangoHud config from dotfiles
  xdg.configFile."MangoHud" = {
    source = "${dotfilesPath}/linux/.config/MangoHud";
    recursive = true;
  };
}
