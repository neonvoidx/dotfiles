# Homebrew env on macOS
if test (uname) = Darwin
    set -gx XDG_CONFIG_HOME "$HOME/.config"
    if test -x /opt/homebrew/bin/brew
        eval "$(/opt/homebrew/bin/brew shellenv fish)"
    end
end

# Interactive set
if status is-interactive
    # Vi mode
    fish_vi_key_bindings
    # Syntax theme
    fish_config theme choose eldritch >/dev/null 2>&1
end

# Environment
set -g fish_greeting ""
set -gx NODE_OPTIONS --max-old-space-size=8192
set -gx DISABLE_AUTO_TITLE true
set -gx ZSH_TAB_TITLE_DISABLE_AUTO_TITLE false
set -gx ZSH_TAB_TITLE_ONLY_FOLDER true
set -gx ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS true
set -gx ZVM_SYSTEM_CLIPBOARD_ENABLED true
set -gx ZSH_DISABLE_COMPFIX true
set -gx FZF_PREVIEW_ADVANCED bat
set -gx FZF_DEFAULT_OPTS '--color=fg:#ebfafa,bg:#282a36,hl:#37f499 --color=fg+:#ebfafa,bg+:#212337,hl+:#37f499 --color=info:#f7c67f,prompt:#04d1f9,pointer:#7081d0 --color=marker:#7081d0,spinner:#f7c67f,header:#323449 --height 80% --layout reverse --border'
set -gx FZF_PATH "$HOME/.config/fzf"
set -gx _ZO_EXCLUDE_DIRS '/Applications/**:**/node_modules'
set -gx _ZO_RESOLVE_SYMLINKS 0
set -gx PYENV_ROOT "$HOME/.pyenv"
set -gx CMAKE_PREFIX_PATH "/usr/local:$CMAKE_PREFIX_PATH"
set -gx LD_LIBRARY_PATH "/usr/local/lib:$LD_LIBRARY_PATH"
set -gx EDITOR nvim
set -gx VISUAL nvim

fish_add_path $HOME/.yarn/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/.rd/bin
fish_add_path $HOME/dev/bin
fish_add_path $HOME/.local/bin
fish_add_path $HOME/go/bin
if test -d "$PYENV_ROOT/bin"
    fish_add_path "$PYENV_ROOT/bin"
end

# Aliases
alias yay='paru'
alias dev='cd ~/dev'
alias findhere='find . -name'
alias e='nvim'

if command -q lazygit
    alias lg='lazygit'
    if command -q yadm
        if test (uname) = Darwin
            alias ly='lazygit --work-tree ~/dotfiles --git-dir ~/dotfiles/.git'
        else if test (uname) = Linux
            alias ly='lazygit --work-tree ~/nix --git-dir ~/nix/.git'
        end
    end
end

if test "$TERM" = xterm-kitty
    alias s='kitten ssh'
    alias icat='kitten icat'
    alias ssh='kitten ssh'
    alias d='kitten diff'
end

if command -q lsd
    alias ls='lsd'
    alias l='ls -Al'
    alias lt='ls --tree --ignore-glob=node_modules'
end

if command -q bat
    alias cat='bat'
end

if command -q btop
    alias htop='btop'
    alias top='btop'
end

if command -q brew
    alias brewup='brew upgrade && cd ~/.config/brew && ./brewbackup.sh'
end

if command -q cmake; and command -q ninja
    alias cmakeninja='cmake -S . -B build -G Ninja'
end

if test -f ~/.ssh/scm-script.sh
    alias scm-ssh='bash ~/.ssh/scm-script.sh'
end

# Functions
function findsyms
    set -l search_path .
    if test (count $argv) -ge 1
        set search_path $argv[1]
    end
    find "$search_path" -type l -ls
end

function deleteall
    if test (count $argv) -ne 1
        echo 'Usage: deleteall <name>'
        return 1
    end
    find . -name "$argv[1]" -exec rm -rf {} \;
end

function y
    set -l tmp (mktemp -t yazi-cwd.XXXXXX)
    yazi $argv --cwd-file="$tmp"
    if test -f "$tmp"
        set -l cwd (cat -- "$tmp")
        if test -n "$cwd"; and test "$cwd" != "$PWD"
            cd -- "$cwd"
        end
    end
    rm -f -- "$tmp"
end

if command -q yazi
    function yy
        set -l tmp (mktemp -t yazi-cwd.XXXXXX)
        yazi $argv --cwd-file="$tmp"
        if test -f "$tmp"
            set -l cwd (cat -- "$tmp")
            if test -n "$cwd"; and test "$cwd" != "$PWD"
                cd -- "$cwd"
            end
        end
        rm -f -- "$tmp"
    end
end

if test "$TERM" = xterm-kitty
    function kk
        if test (count $argv) -lt 1
            echo 'Usage: kk <text>'
            return 1
        end
        kitten @ send-text --match-tab state:focused "$argv[1]"; and kitten @ send-key --match-tab state:focused Enter
    end
end

function reload-ssh
    ssh-add -e /usr/local/lib/opensc-pkcs11.so >/dev/null
    if test $status -gt 0
        echo 'Failed to remove previous card'
    end
    ssh-add -s /usr/local/lib/opensc-pkcs11.so
end

function timezsh
    set -l shell $SHELL
    if test (count $argv) -ge 1
        set shell $argv[1]
    end
    for _i in (seq 1 10)
        /usr/bin/time $shell -i -c exit
    end
end

function ffmpeg-downsize
    if not command -q ffmpeg
        echo 'ffmpeg not found. Please install ffmpeg.'
        return 1
    end

    if test (count $argv) -eq 0
        echo 'Usage: ffmpeg-downsize <inputfile.mov>'
        return 1
    end

    set -l input "$argv[1]"
    set -l output (string replace -r '\\.[^.]+$' '' -- "$input")
    ffmpeg -i "$input" -c:v libx264 -c:a copy -crf 20 "$output-small.mov"
end

function ffmpeg-togif
    if not command -q ffmpeg
        echo 'ffmpeg not found. Please install ffmpeg.'
        return 1
    end

    if test (count $argv) -ne 3
        echo 'Usage: ffmpeg-togif <input.mp4> <start_time> <duration>'
        echo 'Example: ffmpeg-togif movie.mp4 6 8.8'
        return 1
    end

    set -l input "$argv[1]"
    set -l start "$argv[2]"
    set -l duration "$argv[3]"
    set -l base (string replace -r '\\.[^.]+$' '' -- "$input")

    ffmpeg -ss "$start" -t "$duration" -i "$input" -vf "fps=30,scale=400:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "$base.gif"
end

# Optional helper from zsh setup
if command -q pay-respects
    eval "$(pay-respects fish --alias)"
end

# SSH agent start if necessary
if not set -q SSH_AGENT_PID; and not set -q SSH_TTY
    ssh-agent -c | source >/dev/null
end

if test (uname) = Darwin
    if test -f ~/.ssh/scm-script.sh
        scm-ssh start_agent >/dev/null 2>&1
    end
end

# Interactive-only integrations
if status is-interactive
    # History tuning (fish-native equivalents of zsh history behavior)
    function __history_merge_on_prompt --on-event fish_prompt
        history merge
    end

    function __history_save_on_postexec --on-event fish_postexec
        history save
    end

    function fish_should_add_to_history
        set -l cmd "$argv[1]"

        # Match zsh HIST_IGNORE_SPACE behavior.
        if string match -qr '^[[:space:]]' -- "$cmd"
            return 1
        end

        # Match zsh HIST_IGNORE_DUPS behavior (consecutive duplicate entries).
        if set -q __last_history_cmd; and test "$cmd" = "$__last_history_cmd"
            return 1
        end

        set -g __last_history_cmd "$cmd"
        return 0
    end

    # fzf key bindings (including Ctrl+r history)
    set -gx FZF_CTRL_T_COMMAND ""
    if test -f ~/.fzf.fish
        source ~/.fzf.fish
    else if test -f /opt/homebrew/opt/fzf/shell/key-bindings.fish
        source /opt/homebrew/opt/fzf/shell/key-bindings.fish
    else if test -f /usr/local/opt/fzf/shell/key-bindings.fish
        source /usr/local/opt/fzf/shell/key-bindings.fish
    else if test -f /usr/share/fzf/key-bindings.fish
        source /usr/share/fzf/key-bindings.fish
    end

    if functions -q fzf_configure_bindings
        fzf_configure_bindings --history=\cr
    else if functions -q fzf_key_bindings
        fzf_key_bindings
        if functions -q __fzf_search_history
            bind \cr '__fzf_search_history'
        else if functions -q __fzf_history_search
            bind \cr '__fzf_history_search'
        end
    else if functions -q __fzf_search_history
        bind \cr '__fzf_search_history'
    else if functions -q __fzf_history_search
        bind \cr '__fzf_history_search'
    end

    # Keep Ctrl+t free for kitty modifier usage.
    bind --erase \ct 2>/dev/null
    bind -M insert --erase \ct 2>/dev/null
    if functions -q fzf-file-widget
        bind \ce fzf-file-widget
        bind -M insert \ce fzf-file-widget
    end

    if command -q starship
        starship init fish | source
    end

    if command -q zoxide
        zoxide init fish --cmd cd --hook pwd | source
    end

    if test -x $HOME/.local/bin/mise
        $HOME/.local/bin/mise activate fish | source
    end
end
