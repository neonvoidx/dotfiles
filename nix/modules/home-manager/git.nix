{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;
    userName = "neonvoidx";
    userEmail = "me@neonvoid.dev";

    delta = {
      enable = true;
      options = {
        navigate = true;
        side-by-side = true;
      };
    };

    extraConfig = {
      init.defaultBranch = "master";
      core = {
        editor = "nvim";
        pager = "delta";
      };
      interactive.diffFilter = "delta --color-only";
      pull.rebase = true;
      push.autoSetupRemote = true;
      http.postBuffer = 157286400;
      rerere.enabled = true;
      column.ui = "auto";
      branch.sort = "-committerdate";
    };

    aliases = {
      lg = "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)' --all";
      squash = "!f(){ git reset $(git commit-tree \"HEAD^{tree}\" \"$@\");};f";
    };
  };
}
