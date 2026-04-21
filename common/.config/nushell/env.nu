# Nushell environment parity with ~/.zshrc

if (uname) == "Darwin" {
  $env.XDG_CONFIG_HOME = $"($env.HOME)/.config"
}

$env.HISTFILE = $"($env.HOME)/.zsh_history"
$env.HISTSIZE = "10000000"
$env.SAVEHIST = "10000000"
$env.HISTDUPE = "erase"

$env.LS_COLORS = "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=00:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;32"
$env.ZVM_SYSTEM_CLIPBOARD_ENABLED = "true"
$env.ZSH_AUTOSUGGEST_STRATEGY = "(history completion match_prev_cmd)"
$env.ZSH_DISABLE_COMPFIX = "true"
$env.NODE_OPTIONS = "--max-old-space-size=8192"
$env.DISABLE_AUTO_TITLE = "true"
$env.ZSH_TAB_TITLE_DISABLE_AUTO_TITLE = "false"
$env.ZSH_TAB_TITLE_ONLY_FOLDER = "true"
$env.ZSH_TAB_TITLE_CONCAT_FOLDER_PROCESS = "true"
$env.FZF_PREVIEW_ADVANCED = "bat"
$env.FZF_DEFAULT_OPTS = "--color=fg:#ebfafa,bg:#282a36,hl:#37f499 --color=fg+:#ebfafa,bg+:#212337,hl+:#37f499 --color=info:#f7c67f,prompt:#04d1f9,pointer:#7081d0 --color=marker:#7081d0,spinner:#f7c67f,header:#323449 --height 80% --layout reverse --border"
$env.FZF_PATH = $"($env.HOME)/.config/fzf"
$env._ZO_EXCLUDE_DIRS = "/Applications/**:**/node_modules"
$env._ZO_RESOLVE_SYMLINKS = "0"
$env.FZF_CTRL_T_COMMAND = ""
$env.PYENV_ROOT = $"($env.HOME)/.pyenv"
$env.CMAKE_PREFIX_PATH = $"/usr/local:($env.CMAKE_PREFIX_PATH?)"
$env.LD_LIBRARY_PATH = $"/usr/local/lib:($env.LD_LIBRARY_PATH?)"

if (($env.SSH_CONNECTION? | is-empty) == false) {
  $env.EDITOR = "nvim"
  $env.VISUAL = "nvim"
} else {
  $env.EDITOR = "vim"
  $env.VISUAL = "vim"
}

if (which wslu | length) > 0 {
  $env.BROWSER = "wslview"
}

let extra_path = [
  "/opt/cuda/bin"
  $"($env.HOME)/.yarn/bin"
  $"($env.HOME)/.cargo/bin"
  $"($env.HOME)/.rd/bin"
  $"($env.HOME)/dev/bin"
  $"($env.HOME)/.local/bin"
  $"($env.HOME)/go/bin"
  "/Applications/flameshot.app/"
]

if (($env.PYENV_ROOT | path join "bin" | path exists)) {
  $env.PATH = (($env.PATH | append ($env.PYENV_ROOT | path join "bin") | append $extra_path) | uniq)
} else {
  $env.PATH = (($env.PATH | append $extra_path) | uniq)
}
