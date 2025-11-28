{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # Source gitconfig from dotfiles
  home.file = {
    ".gitconfig".source = "${dotfilesPath}/common/.gitconfig";
    ".gitconfig.local".source = "${dotfilesPath}/linux/.gitconfig.local";
  };

  # Enable delta for diffs (program needs to be available)
  programs.git = {
    enable = true;
    delta.enable = true;
  };
}
