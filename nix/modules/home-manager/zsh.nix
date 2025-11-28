{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    
    history = {
      size = 10000;
      save = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
    };

    shellAliases = {
      # Replace commands with better alternatives
      ls = "lsd";
      l = "ls -Al";
      lt = "ls --tree --ignore-glob=node_modules";
      cat = "bat";
      htop = "btop";
      top = "btop";
      
      # Git shortcuts
      lg = "lazygit";
      
      # Navigation
      dev = "cd ~/dev";
      
      # Editor
      e = "nvim";
      
      # Kitty specific
      s = "kitten ssh";
      icat = "kitten icat";
      ssh = "kitten ssh";
      d = "kitten diff";
      
      # Hyprland config
      hypr = "e ~/.config/hypr/hyprland.conf";
    };

    initExtra = ''
      # LS_COLORS for completion
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'lsd $realpath'

      # Hex color support
      zmodload zsh/nearcolor

      # Pure Prompt styling
      export PURE_PROMPT_SYMBOL="󰤇 "
      export PURE_CMD_MAX_EXEC_TIME=0
      zstyle :prompt:pure:git:arrow color "#f16c75"
      zstyle :prompt:pure:git:branch color "#04d1f9"
      zstyle :prompt:pure:path color "#37f499"
      zstyle :prompt:pure:prompt:error color "#f16c75"
      zstyle :prompt:pure:prompt:success color "#37f499"
      zstyle :prompt:pure:prompt:continuation color "#f7c67f"
      zstyle :prompt:pure:suspended_jobs color "#f16c75"
      zstyle :prompt:pure:user color "#a48cf2"
      zstyle :prompt:pure:user:root color "#f1fc79"

      # Vim mode for ZSH
      export ZVM_SYSTEM_CLIPBOARD_ENABLED=true

      # Find symlinks function
      function findsyms() {
        local search_path="''${1:-.}"
        find "$search_path" -type l -ls
      }
      alias findhere="find . -name"

      # Delete all files/folders with a given name recursively
      function deleteall() {
        find . -name "$1" -exec rm -rf {} \;
      }

      # Yazi file manager with cd on exit
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      function yy() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # Kitty send text/key helper
      function kk() {
        kitten @ send-text --match-tab state:focused $1 && kitten @ send-key --match-tab state:focused Enter
      }

      # Yubikey handler (adjust path for NixOS if using opensc)
      reload-ssh() {
        local opensc_lib="$(find /nix/store -name 'opensc-pkcs11.so' 2>/dev/null | head -n1)"
        if [ -n "$opensc_lib" ]; then
          ssh-add -e "$opensc_lib" >> /dev/null
          if [ $? -gt 0 ]; then
            echo "Failed to remove previous card"
          fi
          ssh-add -s "$opensc_lib"
        else
          echo "opensc-pkcs11.so not found in Nix store"
        fi
      }

      # ZSH plugin load times
      timezsh() {
        shell=''${1-$SHELL}
        for i in $(seq 1 10); do command time $shell -i -c exit; done
      }

      # FFmpeg helpers
      ffmpeg-downsize() {
        if ! command -v ffmpeg &> /dev/null; then
          echo "ffmpeg not found. Please install ffmpeg."
          return 1
        fi
        if [ $# -eq 0 ]; then
          echo "Usage: movconvert <inputfile.mov>"
          return 1
        fi
        local output="''${1%.*}"
        ffmpeg -i "$1" -c:v libx264 -c:a copy -crf 20 "''${output}-small.mov"
      }

      ffmpeg-togif() {
        if ! command -v ffmpeg &> /dev/null; then
          echo "ffmpeg not found. Please install ffmpeg."
          return 1
        fi
        if [ $# -ne 3 ]; then
          echo "Usage: togif <input.mp4> <start_time> <duration>"
          echo "Example: togif movie.mp4 6 8.8"
          return 1
        fi
        local input="$1"
        local start="$2"
        local duration="$3"
        local base="''${input%.mp4}"
        ffmpeg -ss "$start" -t "$duration" -i "$input" -vf "fps=30,scale=400:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "''${base}.gif"
      }

      # SSH agent start if necessary
      if [ -z $SSH_AGENT_PID ] && [ -z $SSH_TTY ]; then
        eval $(ssh-agent -s) > /dev/null
      fi

      # Run fastfetch on shell start
      if command -v fastfetch &> /dev/null; then
        fastfetch
      fi
    '';

    plugins = [
      {
        name = "pure";
        src = pkgs.fetchFromGitHub {
          owner = "sindresorhus";
          repo = "pure";
          rev = "v1.23.0";
          sha256 = "sha256-BmQO4xqd/3QnpLUitD2obVxL0UulpboT8jGNEh4ri8k=";
        };
      }
      {
        name = "zsh-vi-mode";
        src = pkgs.fetchFromGitHub {
          owner = "jeffreytse";
          repo = "zsh-vi-mode";
          rev = "v0.11.0";
          sha256 = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
        };
      }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.1.2";
          sha256 = "sha256-Qv8zAiMtrr67CbLRrFjGaPzFZcOiMVEFLg1Z+N6VMhg=";
        };
      }
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--color=fg:#ebfafa,bg:#282a36,hl:#37f499"
      "--color=fg+:#ebfafa,bg+:#212337,hl+:#37f499"
      "--color=info:#f7c67f,prompt:#04d1f9,pointer:#7081d0"
      "--color=marker:#7081d0,spinner:#f7c67f,header:#323449"
      "--height 80%"
      "--layout reverse"
      "--border"
    ];
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.thefuck = {
    enable = true;
    enableZshIntegration = true;
  };
}
