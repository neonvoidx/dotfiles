{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # Consolidated dotfiles symlinking
    ../../modules/home-manager/dotfiles.nix
    
    # Program-specific configurations
    ../../modules/home-manager/kitty.nix
    ../../modules/home-manager/zsh.nix
    ../../modules/home-manager/bash.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/btop.nix
    ../../modules/home-manager/bat.nix
    ../../modules/home-manager/lsd.nix
    ../../modules/home-manager/yazi.nix
    ../../modules/home-manager/lazygit.nix
    ../../modules/home-manager/mpv.nix
    ../../modules/home-manager/hyprland.nix
    ../../modules/home-manager/hypridle.nix
    ../../modules/home-manager/hyprlock.nix
    ../../modules/home-manager/gtk.nix
    ../../modules/home-manager/fastfetch.nix
    ../../modules/home-manager/mangohud.nix
    ../../modules/home-manager/walker.nix
  ];

  home = {
    username = "neonvoid";
    homeDirectory = "/home/neonvoid";
    stateVersion = "24.05";

    # Environment variables from zshrc
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      NODE_OPTIONS = "--max-old-space-size=8192";
      ZSH_AUTOSUGGEST_STRATEGY = "history completion match_prev_cmd";
      ZSH_DISABLE_COMPFIX = "true";
      DISABLE_AUTO_TITLE = "true";
      ZSH_TAB_TITLE_DISABLE_AUTO_TITLE = "false";
      ZSH_TAB_TITLE_ONLY_FOLDER = "true";
      ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS = "true";
      FZF_PREVIEW_ADVANCED = "bat";
      FZF_DEFAULT_OPTS = "--color=fg:#ebfafa,bg:#282a36,hl:#37f499 --color=fg+:#ebfafa,bg+:#212337,hl+:#37f499 --color=info:#f7c67f,prompt:#04d1f9,pointer:#7081d0 --color=marker:#7081d0,spinner:#f7c67f,header:#323449 --height 80% --layout reverse --border";
      _ZO_EXCLUDE_DIRS = "/Applications/**:**/node_modules";
      _ZO_RESOLVE_SYMLINKS = "0";
    };

    sessionPath = [
      "$HOME/.yarn/bin"
      "$HOME/.cargo/bin"
      "$HOME/.rd/bin"
      "$HOME/dev/bin"
      "$HOME/.local/bin"
      "$HOME/go/bin"
      "$HOME/.local/share/fnm"
      "$HOME/.pyenv/bin"
    ];
  };

  # XDG directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
