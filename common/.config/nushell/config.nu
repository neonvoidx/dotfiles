$env.config = ($env.config | upsert history.max_size 10000000)
$env.config = ($env.config | upsert history.sync_on_enter true)
$env.config = ($env.config | upsert history.isolation false)
$env.config = ($env.config | upsert history.file_format "sqlite")
$env.config = ($env.config | upsert show_banner false)

alias e = nvim

def findsyms [search_path = "."] {
  ^find $search_path -type l -ls
}

def findhere [name] {
  ^find . -name $name
}

def deleteall [name] {
  ^find . -name $name -exec rm -rf "{}" ";"
}

def l [] {
  ls -la
}

def lt [] {
  ls **/*
}

alias cat = bat
def lg [...rest] { ^lazygit ...$rest }
def ly [...rest] { ^lazygit --work-tree ~/dotfiles --git-dir ~/dotfiles/.git ...$rest }
def pacq [...rest] { ^~/scripts/fzfpac.sh ...$rest }
alias htop = btop
alias top = btop
def brewup [] { ^brew upgrade; cd ~/.config/brew; ^./brewbackup.sh }
def eup [] { ^nvim --headless "+Lazy! sync" +qa; cd ~/.config/nvim; ^git add .; ^git commit -m "upd"; ^git push }
def cmakeninja [] { ^cmake -S . -B build -G Ninja }

def --env y [...rest] {
  let tmp = (^mktemp -t "yazi-cwd.XXXXXX" | str trim)
  ^yazi ...$rest --cwd-file=$tmp
  let cwd = (open $tmp | str trim)
  if ($cwd | is-not-empty) and ($cwd != $env.PWD) {
    cd $cwd
  }
  rm -f $tmp
}

def --env yy [...rest] {
  y ...$rest
}

def --wrapped ssh [...args] {
  if (($env.TERM? == "xterm-kitty") and ((which kitten | length) > 0)) {
    ^kitten ssh ...$args
  } else {
    ^ssh ...$args
  }
}

def s [...args] { ssh ...$args }
def icat [...args] { if (($env.TERM? == "xterm-kitty") and ((which kitten | length) > 0)) { ^kitten icat ...$args } }
def d [...args] { if (($env.TERM? == "xterm-kitty") and ((which kitten | length) > 0)) { ^kitten diff ...$args } }
def kk [text] {
  if (($env.TERM? == "xterm-kitty") and ((which kitten | length) > 0)) {
    ^kitten @ send-text --match-tab state:focused $text
    ^kitten @ send-key --match-tab state:focused Enter
  }
}

def reload-ssh [] {
  ^ssh-add -e /usr/local/lib/opensc-pkcs11.so
  ^ssh-add -s /usr/local/lib/opensc-pkcs11.so
}

def timezsh [shell?] {
  let shell_cmd = if ($shell | is-empty) { $env.SHELL } else { $shell }
  1..10 | each { ^/usr/bin/time $shell_cmd -i -c exit }
}

def ffmpeg-downsize [input] {
  if (which ffmpeg | length) == 0 {
    print "ffmpeg not found. Please install ffmpeg."
    return
  }
  let output = ($input | str replace --regex '\.[^.]+$' "")
  ^ffmpeg -i $input -c:v libx264 -c:a copy -crf 20 $"($output)-small.mov"
}

def ffmpeg-togif [input start duration] {
  if (which ffmpeg | length) == 0 {
    print "ffmpeg not found. Please install ffmpeg."
    return
  }
  let base = ($input | str replace --regex '\.mp4$' "")
  ^ffmpeg -ss $start -t $duration -i $input -vf "fps=30,scale=400:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" -loop 0 $"($base).gif"
}

def --env _start_ssh_agent [] {
  let agent_lines = (^ssh-agent -s | lines | where ($it | str contains "="))
  let entries = ($agent_lines | parse -r '^(?<k>[A-Z_]+)=(?<v>[^;]+);')
  let env_rec = ($entries | reduce -f {} {|row, acc| $acc | upsert $row.k $row.v })
  load-env $env_rec
}

if ($nu.is-interactive) {
  if (which zoxide | length) > 0 {
    do -i { ^zoxide init nushell --cmd cd | save -f ~/.config/nushell/zoxide.nu }
  }

  if (which mise | length) > 0 {
    do -i { ^mise activate nu | save -f ~/.config/nushell/mise.nu }
  }

  if (which starship | length) > 0 {
    do -i { ^starship init nu | save -f ~/.config/nushell/starship.nu }
  }

  if (($env.SSH_AGENT_PID? | is-empty) and ($env.SSH_TTY? | is-empty)) {
    do -i { _start_ssh_agent }
  }

  if (("~/.ssh/scm-script.sh" | path expand) | path exists) {
    def scm-ssh [...rest] { ^bash ~/.ssh/scm-script.sh ...$rest }
    do -i { scm-ssh start_agent }
  }

  if (which fastfetch | length) > 0 {
    do -i { fastfetch }
  }
}

source ~/.config/nushell/zoxide.nu
source ~/.config/nushell/mise.nu
source ~/.config/nushell/starship.nu
