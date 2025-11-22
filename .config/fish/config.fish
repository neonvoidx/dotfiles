if status is-interactive
    if not type -q fisher
        curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher
    end
    #  ____   _  _____ _   _ 
    # |  _ \ / \|_   _| | | |
    # | |_) / _ \ | | | |_| |
    # |  __/ ___ \| | |  _  |
    # |_| /_/   \_\_| |_| |_|
    #                        
    fish_add_path /opt/homebrew/bin/
    # fish_add_path $(pyenv root)/shims
    fish_add_path $HOME/.yarn/bin #yarn
    fish_add_path $HOME/.cargo/bin # Rust
    fish_add_path $HOME/.rd/bin # Rancher
    fish_add_path $HOME/.cargo/bin
    # fish_add_path $HOME/.pyenv/bin
    fish_add_path $HOME/dev/bin
    fish_add_path $HOME/.local/bin
    fish_add_path $HOME/go/bin

    # Preferred editor for local and remote sessions
    if test $SSH_CONNECTION
        set EDITOR nvim
        set VISUAL nvim
    else
        set EDITOR vim
        set VISUAL vim
    end
    # # SSH agent start if necessary
    # if test -z "$SSH_AGENT_PID" -a -z "$SSH_TTY" # if no agent & not in ssh
    #     eval (ssh-agent -c) >/dev/null
    # end

    #     _    _     _                    _       _   _                 
    #    / \  | |__ | |__  _ __ _____   _(_) __ _| |_(_) ___  _ __  ___ 
    #   / _ \ | '_ \| '_ \| '__/ _ \ \ / / |/ _` | __| |/ _ \| '_ \/ __|
    #  / ___ \| |_) | |_) | | |  __/\ V /| | (_| | |_| | (_) | | | \__ \
    # /_/   \_\_.__/|_.__/|_|  \___| \_/ |_|\__,_|\__|_|\___/|_| |_|___/
    #                                                                   
    abbr --add e nvim
    abbr --add hypr "e ~/.config/hypr/hyprland.conf"
    abbr --add yay paru
    abbr --add dev "cd ~/dev"
    abbr --add findsyms "find . -type l -ls"
    abbr --add findhere "find . -name"
    abbr --add ys "yarn start"
    abbr --add lg lazygit
    abbr --add ly 'lazygit --use-config-file "$HOME/.config/yadm/lazygit.yml" --work-tree ~ --git-dir ~/.local/share/yadm/repo.git'
    abbr --add cat bat
    abbr --add ls lsd
    abbr --add l "lsd -Al"
    abbr --add lt "lsd --tree"
    abbr --add pacq "~/pacrm.sh"
    abbr --add htop btop
    abbr --add top btop
    abbr --add brewup "brew upgrade && cd ~/.config/brew && ./brewbackup.sh"
    abbr --add eup "nvim --headless '+Lazy! sync' +qa && cd ~/.config/nvim && git add . && git commit -m 'upd' && git push"

    #  _____      
    # |  ___| __  
    # | |_ | '_ \ 
    # |  _|| | | |
    # |_|  |_| |_|
    #             
    function deleteall -d "Delete all files/folders with a given name in the current directory"
        find . -name $argv[1] -exec rm -rf {} \;
    end
    complete -c deleteall -a "(ls)" -d "File/folder name to delete"

    function reload-ssh -d "Reload SSH smartcard agent"
        ssh-add -e /usr/local/lib/opensc-pkcs11.so >>/dev/null
        if test $status -gt 0
            echo "Failed to remove previous card"
        end
        ssh-add -s /usr/local/lib/opensc-pkcs11.so
    end

    function y -d "Open yazi file manager and cd to selected directory"
        set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
    complete -c y -a "(ls)" -d "Directory or file to open with yazi"

    function ffmpeg-downsize -d "Downsize .mov file using ffmpeg"
        if test (count $argv) -eq 0
            echo "Usage: movconvert <inputfile.mov>"
            return 1
        end
        set output (string replace -r '\.mov$' '' $argv[1])
        ffmpeg -i "$argv[1]" -c:v libx264 -c:a copy -crf 20 "$output-small.mov"
    end
    complete -c ffmpeg-downsize -a "*.mov" -d "Input .mov file"

    function ffmpeg-togif -d "Convert mp4 to gif using ffmpeg"
        if test (count $argv) -ne 3
            echo "Usage: togif <input.mp4> <start_time> <duration>"
            echo "Example: togif movie.mp4 6 8.8"
            return 1
        end
        set input $argv[1]
        set start $argv[2]
        set duration $argv[3]
        set base (string replace -r '\.mp4$' '' $input)
        ffmpeg -ss "$start" -t "$duration" -i "$input" -vf "fps=30,scale=400:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 "$base.gif"
    end
    complete -c ffmpeg-togif -a "*.mp4" -d "Input .mp4 file"
    complete -c ffmpeg-togif -n "not __fish_seen_subcommand_from ffmpeg-togif" -a "" -d "Start time (seconds)"
    complete -c ffmpeg-togif -n "not __fish_seen_subcommand_from ffmpeg-togif" -a "" -d "Duration (seconds)"
    # Kitty
    if test "$TERM" = xterm-kitty
        abbr --add cat "kitten icat"
        abbr --add s "kitten ssh"
        abbr --add icat "kitten icat"
        abbr --add ssh "kitten ssh"
        abbr --add d "kitten diff"
        function kk -d "Send text and Enter key to focused Kitty tab"
            kitten @ send-text --match-tab state:focused $1 && kitten @ send-key --match-tab state:focused Enter
        end
    end
    # if lsd, replace ls
    if type -q lsd
        abbr --add ls lsd
        abbr --add l "lsd -Al"
        abbr --add lt "lsd --tree"
    end
    # if bat, replace cat
    if type -q bat
        abbr --add cat bat
    end
    # pacq for fzf package installed search
    if type -q pacman
        abbr --add pacq "pacman -Qq | fzf --preview 'pacman -Qil {}' --layout reverse --bind 'enter:execute(pacman -Qil {} | less)'"
    end
    # if htop, replace btop
    if type -q btop
        abbr --add htop btop
        abbr --add top btop
    end
    # Update Brew packages and backup to brew folder
    if type -q brew
        abbr --add brewup "brew upgrade && cd ~/.config/brew && ./brewbackup.sh"
    end
    # Update neovim lazy packages headless
    if type -q nvim
        abbr --add eup "nvim --headless '+Lazy! sync' +qa && cd ~/.config/nvim && git add . && git commit -m 'upd' && git push"
    end
    # GH CLI Copilot Chat
    set -l COPILOT_CLI ~/.local/share/gh/extensions/gh-copilot/gh-copilot
    if not test -e "$COPILOT_CLI"
        gh extension install github/gh-copilot --force
    end
    # GH CLI gh-clone-org
    # gh clone-org ORGNAME
    set -l CLONE_ORG ~/.local/share/gh/extensions/gh-clone-org/gh-clone-org
    if not test -e "$CLONE_ORG"
        gh extension install matt-bartel/gh-clone-org --force
    end
    # If fastfetch then call on profile load
    if type -q fastfetch
        fastfetch
    end

    #  _____            _ 
    # | ____|_   ____ _| |
    # |  _| \ \ / / _` | |
    # | |___ \ V / (_| | |
    # |_____| \_/ \__,_|_|
    #                     
    thefuck --alias | source
    direnv hook fish | source
    fnm env --shell fish | source

    #  _____ _     _       ____                  _  __ _      
    # |  ___(_)___| |__   / ___| _ __   ___  ___(_)/ _(_) ___ 
    # | |_  | / __| '_ \  \___ \| '_ \ / _ \/ __| | |_| |/ __|
    # |  _| | \__ \ | | |  ___) | |_) |  __/ (__| |  _| | (__ 
    # |_|   |_|___/_| |_| |____/| .__/ \___|\___|_|_| |_|\___|
    #                           |_|                           
    # Vi Mode
    set -g fish_key_bindings fish_vi_key_bindings
    set fish_cursor_default block
    set fish_cursor_insert line
    # MOTD for fish 
    set fish_greeting

    #                                  _   
    #  _ __  _ __ ___  _ __ ___  _ __ | |_ 
    # | '_ \| '__/ _ \| '_ ` _ \| '_ \| __|
    # | |_) | | | (_) | | | | | | |_) | |_ 
    # | .__/|_|  \___/|_| |_| |_| .__/ \__|
    # |_|                       |_|        
    # Pure Prompt
    set --universal pure_check_for_new_release false
    set --universal pure_symbol_prompt ""
    set --universal pure_separate_prompt_on_error false
    set --universal pure_threshold_command_duration 0
    set --universal pure_show_subsecond_command_duration true
    set --universal pure_reverse_prompt_symbol_in_vimode true # Reverse prompt char in vi mode
    set --universal pure_symbol_ssh_prefix "󰣀 "
    set --universal pure_symbol_git_stash "󰘓 "
    set --universal pure_symbol_git_unpulled_commits " "
    set --universal pure_symbol_git_unpushed_commits " "
    set --universal pure_symbol_git_dirty "  "
    set --universal pure_color_git_dirty green

    #  _____                 _   _                 
    # |  ___|   _ _ __   ___| |_(_) ___  _ __  ___ 
    # | |_ | | | | '_ \ / __| __| |/ _ \| '_ \/ __|
    # |  _|| |_| | | | | (__| |_| | (_) | | | \__ \
    # |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/
    #                                              
    function last_history_item -d "Print the last item from shell history"
        echo $history[1]
    end
    abbr -a !! --position anywhere --function last_history_item
    # Git squash master to one commit, pass true as first param to use yadm instead of git
    function squashdown -a use_yadm -d "Squash master branch to one commit using git or yadm"
        # Default to git if parameter not provided
        set -q use_yadm; or set use_yadm false

        # Choose command based on parameter
        set cmd git
        if test "$use_yadm" = true
            set cmd yadm
        end

        $cmd checkout --orphan squashed master
        $cmd commit -m "Squashed down 🎉️"
        $cmd branch -M squashed master
    end
    complete -c squashdown -a "true false" -d "Use yadm (true) or git (false)"

    #   __     __         _             _       
    #  / _|___/ _|  _ __ | |_   _  __ _(_)_ __  
    # | ||_  / |_  | '_ \| | | | |/ _` | | '_ \ 
    # |  _/ /|  _| | |_) | | |_| | (_| | | | | |
    # |_|/___|_|   | .__/|_|\__,_|\__, |_|_| |_|
    #              |_|            |___/         
    fzf_configure_bindings --directory=\cf --git_log=\cg --history=\cr --processes=\cp$pure_shorten_window_title_current_directory_length
end

set -gx ZSH_DISABLE_COMPFIX true
set -gx NODE_OPTIONS --max-old-space-size=8192
set -gx PATH $PATH /opt/cuda/bin
set -gx PATH $PATH $HOME/.yarn/bin
set -gx PATH $PATH $HOME/.cargo/bin
set -gx PATH $PATH $HOME/.rd/bin
set -gx PATH $PATH $HOME/dev/bin
set -gx PATH $PATH $HOME/.local/bin
set -gx PATH $PATH $HOME/go/bin
set -gx PATH $PATH /Applications/flameshot.app/
set -gx DISABLE_AUTO_TITLE true
set -gx ZSH_TAB_TITLE_DISABLE_AUTO_TITLE false
set -gx ZSH_TAB_TITLE_ONLY_FOLDER true
set -gx ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS true
set -gx FZF_PREVIEW_ADVANCED bat
set -gx FZF_DEFAULT_OPTS '--color=fg:#ebfafa,bg:#282a36,hl:#37f499 --color=fg+:#ebfafa,bg+:#212337,hl+:#37f499 --color=info:#f7c67f,prompt:#04d1f9,pointer:#7081d0 --color=marker:#7081d0,spinner:#f7c67f,header:#323449 --height 80% --layout reverse --border'
set -gx FZF_PATH "$HOME/.config/fzf"
set -gx _ZO_EXCLUDE_DIRS "/Applications/**:**/node_modules"
set -gx _ZO_RESOLVE_SYMLINKS 1
set -gx FZF_CTRL_T_COMMAND ""
set -gx PATH "$HOME/.local/share/fnm" $PATH
set -gx FNM_DIR "$HOME/.cache/fnm"
set -gx COPILOT_CLI "$HOME/.local/share/gh/extensions/gh-copilot/gh-copilot"
set -gx CLONE_ORG "$HOME/.local/share/gh/extensions/gh-clone-org/gh-clone-org"
set -gx PYENV_ROOT "$HOME/.pyenv"
if test -d "$PYENV_ROOT/bin"
    set -gx PATH "$PYENV_ROOT/bin" $PATH
end
set -gx PATH "/home/neonvoid/.opencode/bin" $PATH

abbr --add hypr "e ~/.config/hypr/hyprland.conf"
abbr --add yay paru
abbr --add dev "cd ~/dev"
abbr --add findhere "find . -name"
abbr --add e nvim
abbr --add lg lazygit
abbr --add ly 'lazygit --use-config-file "$HOME/.config/yadm/lazygit.yml" --work-tree ~ --git-dir ~/.local/share/yadm/repo.git'
abbr --add cat bat
abbr --add ls lsd
abbr --add l "lsd -Al"
abbr --add lt "lsd --tree --ignore-glob=node_modules"
abbr --add pacq "~/pacrm.sh"
abbr --add htop btop
abbr --add top btop
abbr --add brewup "brew upgrade && cd ~/.config/brew && ./brewbackup.sh"
abbr --add eup "nvim --headless '+Lazy! sync' +qa && cd ~/.config/nvim && git add . && git commit -m 'upd' && git push"

if test $SSH_CONNECTION
    set -gx EDITOR nvim
    set -gx VISUAL nvim
else
    set -gx EDITOR vim
    set -gx VISUAL vim
end

function findsyms -d "Find and list symlinks in a directory"
    set search_path (count $argv) >/dev/null; and set search_path $argv[1]; or set search_path .
    find $search_path -type l -ls
end
complete -c findsyms -a "(ls -d */)" -d "Directory to search for symlinks"

set -g fish_key_bindings fish_vi_key_bindings

function fish_title -d "Show current directory name in terminal title"
    echo (basename $PWD)
end
