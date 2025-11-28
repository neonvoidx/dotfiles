{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Symlink mpv config from dotfiles
  xdg.configFile."mpv" = {
    source = "${dotfilesPath}/common/.config/mpv";
    recursive = true;
  };
}
