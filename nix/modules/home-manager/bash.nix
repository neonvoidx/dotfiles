{ config, pkgs, lib, ... }:

let
  dotfilesPath = ../../../..;
in
{
  # Source bashrc and bash_profile from dotfiles
  home.file = {
    ".bashrc".source = "${dotfilesPath}/common/.bashrc";
    ".bash_profile".source = "${dotfilesPath}/common/.bash_profile";
  };
}
