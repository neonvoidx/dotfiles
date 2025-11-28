{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;
    autocd = true;
    
    history = {
      size = 10000000;
      save = 10000000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      share = true;
      extended = true;
    };

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
      PURE_PROMPT_SYMBOL = "󰤇 ";
      PURE_CMD_MAX_EXEC_TIME = "0";
    };

    shellAliases = {
      hypr = "e ~/.config/hypr/hyprland.conf";
      dev = "cd ~/dev";
      findhere = "find . -name";
      e = "nvim";
      lg = "lazygit";
      ls = "lsd";
      l = "ls -Al";
      lt = "ls --tree --ignore-glob=node_modules";
      cat = "bat";
      htop = "btop";
      top = "btop";
      s = "kitten ssh";
      icat = "kitten icat";
      ssh = "kitten ssh";
      d = "kitten diff";
    };

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

    initExtra = ''
      # Hex color support
      zmodload zsh/nearcolor
      
      # Pure prompt styling
      zstyle :prompt:pure:git:arrow color "#f16c75"
      zstyle :prompt:pure:git:branch color "#04d1f9"
      zstyle :prompt:pure:path color "#37f499"
      zstyle :prompt:pure:prompt:error color "#f16c75"
      zstyle :prompt:pure:prompt:success color "#37f499"
      zstyle :prompt:pure:prompt:continuation color "#f7c67f"
      zstyle :prompt:pure:suspended_jobs color "#f16c75"
      zstyle :prompt:pure:user color "#a48cf2"
      zstyle :prompt:pure:user:root color "#f1fc79"
      
      # Completion styling
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'lsd $realpath'
      
      # Yazi function
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
      
      # FFmpeg helpers
      ffmpeg-downsize() {
        if ! command -v ffmpeg &> /dev/null; then
          echo "ffmpeg not found."
          return 1
        fi
        if [ $# -eq 0 ]; then
          echo "Usage: ffmpeg-downsize <inputfile.mov>"
          return 1
        fi
        local output="''${1%.*}"
        ffmpeg -i "$1" -c:v libx264 -c:a copy -crf 20 "''${output}-small.mov"
      }
      
      ffmpeg-togif() {
        if ! command -v ffmpeg &> /dev/null; then
          echo "ffmpeg not found."
          return 1
        fi
        if [ $# -ne 3 ]; then
          echo "Usage: togif <input.mp4> <start_time> <duration>"
          return 1
        fi
        local input="$1"
        local start="$2"
        local duration="$3"
        local base="''${input%.mp4}"
        ffmpeg -ss "$start" -t "$duration" -i "$input" -vf "fps=30,scale=400:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "''${base}.gif"
      }
      
      # Run fastfetch on shell start
      if command -v fastfetch &> /dev/null; then
        fastfetch
      fi
    '';
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [ "--cmd cd" ];
  };

  programs.thefuck = {
    enable = true;
    enableZshIntegration = true;
    alias = "fk";
  };
}
