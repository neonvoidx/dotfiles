{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Source bashrc and bash_profile from dotfiles
  home.file = {
    ".bashrc".source = "${dotfilesPath}/common/.bashrc";
    ".bash_profile".source = "${dotfilesPath}/common/.bash_profile";
  };
}
