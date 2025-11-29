{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Environment variables
    sessionVariables = {
      # ZSH specific
      ZVM_SYSTEM_CLIPBOARD_ENABLED = "true";
      ZSH_AUTOSUGGEST_STRATEGY = "(history completion match_prev_cmd)";
      ZSH_DISABLE_COMPFIX = "true";
      
      # NodeJS
      NODE_OPTIONS = "--max-old-space-size=8192";
      
      # ZSH Tab title for kitty
      DISABLE_AUTO_TITLE = "true";
      ZSH_TAB_TITLE_DISABLE_AUTO_TITLE = "false";
      ZSH_TAB_TITLE_ONLY_FOLDER = "true";
      ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS = "true";
      
      # FZF
      FZF_PREVIEW_ADVANCED = "bat";
      FZF_DEFAULT_OPTS = "--color=fg:#ebfafa,bg:#282a36,hl:#37f499 --color=fg+:#ebfafa,bg+:#212337,hl+:#37f499 --color=info:#f7c67f,prompt:#04d1f9,pointer:#7081d0 --color=marker:#7081d0,spinner:#f7c67f,header:#323449 --height 80% --layout reverse --border";
      FZF_PATH = "$HOME/.config/fzf";
      FZF_CTRL_T_COMMAND = "";
      
      # Zoxide
      _ZO_EXCLUDE_DIRS = "/Applications/**:**/node_modules";
      _ZO_RESOLVE_SYMLINKS = "0";
      
      # PyEnv
      PYENV_ROOT = "$HOME/.pyenv";
      
      # CMake
      CMAKE_PREFIX_PATH = "/usr/local:$CMAKE_PREFIX_PATH";
      LD_LIBRARY_PATH = "/usr/local/lib:$LD_LIBRARY_PATH";
      
      # Editor
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # PATH additions
    sessionVariables.PATH = lib.mkAfter [
      "/opt/cuda/bin"
      "$HOME/.yarn/bin"
      "$HOME/.cargo/bin"
      "$HOME/.rd/bin"
      "$HOME/dev/bin"
      "$HOME/.local/bin"
      "$HOME/go/bin"
      "/Applications/flameshot.app/"
      "$HOME/.pyenv/bin"
    ].join(":");

    # Shell aliases
    shellAliases = {
      # Config shortcuts
      hypr = "e ~/.config/hypr/hyprland.conf";
      yay = "paru";
      dev = "cd ~/dev";
      
      # Editor
      e = "nvim";
      
      # Git
      lg = "lazygit";
      ly = "lazygit --work-tree ~/dotfiles --git-dir ~/dotfiles/.git";
      
      # Kitty (only when in kitty)
      s = "kitten ssh";
      icat = "kitten icat";
      ssh = "kitten ssh";
      d = "kitten diff";
      
      # Modern replacements
      ls = "lsd";
      l = "ls -Al";
      lt = "ls --tree --ignore-glob=node_modules";
      cat = "bat";
      htop = "btop";
      top = "btop";
      
      # Pacman
      pacq = "~/scripts/fzfpac.sh";
      
      # Brew
      brewup = "brew upgrade && cd ~/.config/brew && ./brewbackup.sh";
      
      # Neovim
      eup = "nvim --headless '+Lazy! sync' +qa && cd ~/.config/nvim && git add . && git commit -m 'upd' && git push";
      
      # pay-respects
      f = "$(pay-respects zsh)";
      
      # CMake
      cmakeninja = "cmake -S . -B build -G Ninja";
    };

    # Shell initialization
    initExtra = ''
      # Hex color support
      zmodload zsh/nearcolor
      
      # Pure Prompt configuration
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
      
      # Completion styling
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' menu no 
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'lsd $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'lsd $realpath'
      
      # FZF functions
      _fzf_compgen_path() {
        fd --hidden --follow . "$1"
      }
      _fzf_compgen_dir() {
        fd --type d --hidden --follow . "$1"
      }
      
      # Functions
      findsyms() {
        local search_path="''${1:-.}"
        find "$search_path" -type l -ls
      }
      
      deleteall() {
        find . -name "$1" -exec rm -rf {} \;
      }
      
      # Yazi with directory change
      y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
      
      # Kitty broadcast function
      kk() {
        kitten @ send-text --match-tab state:focused $1 && kitten @ send-key --match-tab state:focused Enter
      }
      
      # Yubikey SSH reload
      reload-ssh() {
        ssh-add -e /usr/local/lib/opensc-pkcs11.so >> /dev/null
        if [ $? -gt 0 ]; then
          echo "Failed to remove previous card"
        fi
        ssh-add -s /usr/local/lib/opensc-pkcs11.so
      }
      
      # ZSH profiling
      timezsh() {
        shell=''${1-$SHELL}
        for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
      }
      
      # FFmpeg downsize
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
      
      _ffmpeg_downsize() {
        _arguments '*:input file:_files'
      }
      compdef _ffmpeg_downsize ffmpeg-downsize
      
      # FFmpeg to GIF
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
      
      _ffmpeg_togif() {
        _arguments \
          '1:input file:_files' \
          '2:start time (seconds):' \
          '3:duration (seconds):'
      }
      compdef _ffmpeg_togif ffmpeg-togif
      
      # SSH agent start if necessary
      if [ -z $SSH_AGENT_PID ] && [ -z $SSH_TTY ]; then
        eval `ssh-agent -s` > /dev/null
      fi
      
      # SCM SSH script
      if [ -f ~/.ssh/scm-script.sh ]; then
        alias scm-ssh='bash ~/.ssh/scm-script.sh'
        scm-ssh start_agent >/dev/null 2>&1
      fi
      
      # Initialize zoxide
      eval "$(zoxide init zsh --cmd cd --hook pwd)"
      
      # GH Copilot CLI
      COPILOT_CLI=~/.local/share/gh/extensions/gh-copilot/gh-copilot
      if [ -f "$COPILOT_CLI" ]; then
        eval "$(gh copilot alias -- zsh)"
      else
        gh extension install github/gh-copilot 2>/dev/null
      fi
      
      # GH clone-org extension
      CLONE_ORG=~/.local/share/gh/extensions/gh-clone-org/gh-clone-org
      if [ ! -f "$CLONE_ORG" ]; then
        gh extension install matt-bartel/gh-clone-org 2>/dev/null
      fi
      
      # FZF integration
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
      
      # Fastfetch on startup
      if command -v fastfetch &> /dev/null; then
        fastfetch
      fi
    '';

    # History configuration
    history = {
      size = 10000;
      save = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreAllDups = true;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      share = true;
    };
  };
}
