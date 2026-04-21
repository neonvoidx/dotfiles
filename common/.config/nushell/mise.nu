def "parse vars" [] {
  $in | from csv --noheaders --no-infer | rename 'op' 'name' 'value'
}

def --env "update-env" [] {
  for $var in $in {
    if $var.op == "set" {
      if ($var.name | str upcase) == 'PATH' {
        $env.PATH = ($var.value | split row (char esep))
      } else {
        load-env {($var.name): $var.value}
      }
    } else if $var.op == "hide" and $var.name in $env {
      hide-env $var.name
    }
  }
}
export-env {
  
  'set,PATH,/Users/jrreed/.codex/tmp/arg0/codex-arg0KxpLQq:/opt/homebrew/bin:/opt/homebrew/sbin:/Users/jrreed/.local/share/zinit/polaris/bin:/Users/jrreed/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/Library/Frameworks/Python.framework/Versions/3.8/bin:/usr/local/bin:/System/Cryptexes/App/usr/bin:/usr/bin:/bin:/usr/sbin:/sbin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin:/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin:/opt/pmk/env/global/bin:/Library/TeX/texbin:/Users/jrreed/.cargo/bin:/Applications/kitty.app/Contents/MacOS:/Users/jrreed/.local/bin:/opt/cuda/bin:/Users/jrreed/.yarn/bin:/Users/jrreed/.rd/bin:/Users/jrreed/dev/bin:/Users/jrreed/go/bin:/Applications/flameshot.app/
hide,MISE_SHELL,
hide,__MISE_DIFF,
hide,__MISE_DIFF,' | parse vars | update-env
  $env.MISE_SHELL = "nu"
  let mise_hook = {
    condition: { "MISE_SHELL" in $env }
    code: { mise_hook }
  }
  add-hook hooks.pre_prompt $mise_hook
  add-hook hooks.env_change.PWD $mise_hook
}

def --env add-hook [field: cell-path new_hook: any] {
  let field = $field | split cell-path | update optional true | into cell-path
  let old_config = $env.config? | default {}
  let old_hooks = $old_config | get $field | default []
  $env.config = ($old_config | upsert $field ($old_hooks ++ [$new_hook]))
}

export def --env --wrapped main [command?: string, --help, ...rest: string] {
  let commands = ["deactivate", "shell", "sh"]

  if ($command == null) {
    ^"/Users/jrreed/.local/bin/mise"
  } else if ($command == "activate") {
    $env.MISE_SHELL = "nu"
  } else if ($command in $commands) {
    ^"/Users/jrreed/.local/bin/mise" $command ...$rest
    | parse vars
    | update-env
  } else {
    ^"/Users/jrreed/.local/bin/mise" $command ...$rest
  }
}

def --env mise_hook [] {
  ^"/Users/jrreed/.local/bin/mise" hook-env -s nu
    | parse vars
    | update-env
}

