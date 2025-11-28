{ config, pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    
    historyControl = [ "ignoredups" "ignorespace" ];
    historySize = 10000;
    historyFileSize = 20000;
    
    shellAliases = {
      ls = "lsd";
      l = "ls -Al";
      lt = "ls --tree --ignore-glob=node_modules";
      cat = "bat";
      htop = "btop";
      top = "btop";
      lg = "lazygit";
      dev = "cd ~/dev";
      e = "nvim";
    };

    bashrcExtra = ''
      # If not running interactively, don't do anything
      case $- in
      *i*) ;;
      *) return ;;
      esac

      # Zoxide integration
      eval "$(zoxide init --cmd cd bash)"
    '';

    profileExtra = ''
      # Source bashrc
      [[ -f ~/.bashrc ]] && . ~/.bashrc
    '';
  };
}
