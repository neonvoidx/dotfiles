{ config, pkgs, lib, ... }:

let
  # Path to the dotfiles repository root (resolved at flake evaluation time)
  # This relative path is standard for Nix flakes
  dotfilesPath = ../../../..;
in
{
  # ============================================================================
  # Home directory dotfiles (shell configs, git, etc.)
  # ============================================================================
  home.file = {
    # Shell configs
    ".zshrc".source = "${dotfilesPath}/common/.zshrc";
    ".bashrc".source = "${dotfilesPath}/common/.bashrc";
    ".bash_profile".source = "${dotfilesPath}/common/.bash_profile";

    # Git configs
    ".gitconfig".source = "${dotfilesPath}/common/.gitconfig";
    ".gitconfig.local".source = "${dotfilesPath}/linux/.gitconfig.local";

    # Linux-specific kitty config override
    ".config/kitty/kitty.conf.local".source = "${dotfilesPath}/linux/.config/kitty/kitty.conf";
  };

  # ============================================================================
  # XDG config directory symlinks
  # ============================================================================
  xdg.configFile = {
    # From common/.config/
    "kitty" = {
      source = "${dotfilesPath}/common/.config/kitty";
      recursive = true;
    };
    "btop" = {
      source = "${dotfilesPath}/common/.config/btop";
      recursive = true;
    };
    "bat" = {
      source = "${dotfilesPath}/common/.config/bat";
      recursive = true;
    };
    "lsd" = {
      source = "${dotfilesPath}/common/.config/lsd";
      recursive = true;
    };
    "yazi" = {
      source = "${dotfilesPath}/common/.config/yazi";
      recursive = true;
    };
    "lazygit" = {
      source = "${dotfilesPath}/common/.config/lazygit";
      recursive = true;
    };
    "mpv" = {
      source = "${dotfilesPath}/common/.config/mpv";
      recursive = true;
    };

    # From linux/.config/
    "hypr" = {
      source = "${dotfilesPath}/linux/.config/hypr";
      recursive = true;
    };
    "gtk-2.0" = {
      source = "${dotfilesPath}/linux/.config/gtk-2.0";
      recursive = true;
    };
    "gtk-3.0" = {
      source = "${dotfilesPath}/linux/.config/gtk-3.0";
      recursive = true;
    };
    "gtk-4.0" = {
      source = "${dotfilesPath}/linux/.config/gtk-4.0";
      recursive = true;
    };
    "fastfetch" = {
      source = "${dotfilesPath}/linux/.config/fastfetch";
      recursive = true;
    };
    "MangoHud" = {
      source = "${dotfilesPath}/linux/.config/MangoHud";
      recursive = true;
    };
    "walker" = {
      source = "${dotfilesPath}/linux/.config/walker";
      recursive = true;
    };
  };
}
