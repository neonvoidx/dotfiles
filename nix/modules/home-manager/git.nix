{ config, pkgs, lib, ... }:

{
  # Git config is sourced from dotfiles via dotfiles.nix
  # Enable delta for diffs (program needs to be available)
  programs.git = {
    enable = true;
    delta.enable = true;
  };
}
