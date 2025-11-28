{ config, pkgs, lib, ... }:

let
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
