{ config, pkgs, ...}:
let 
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  create_sym = path: config.lib.file.mkOutOfStoreSymlink path;
in
{
    home.username = "neonvoid";
    home.homeDirectory = "/home/neonvoid";
    home.stateVersion = "25.05";
    programs.git.enable = true;

    home.packages = with pkgs; [ 
      firefox-devedition
      # Aliasing to firefox-developer-edition
      (writeScriptBin "firefox-developer-edition" ''
	exec ${firefox-devedition}/bin/firefoxdevedition "$@"
      '')
      fnm
      github-copilot-cli
      gh
      proton-pass
      protonmail-bridge
      protonup-qt
      thunderbird
    ];
    
    #programs.zsh = {
        #plugins = [];
        #enableAutosuggestions.enable = true;
        #syntaxHighlighting.enable = true;
    #};

    # Symlink dotfiles: common first, then Linux-specific (overrides common)
    home.file = builtins.mapAttrs (name: _: {
      source = create_sym "${dotfiles}/common/${name}";
      recursive = true;
      force = true;
    }) (builtins.readDir "${dotfiles}/common") // builtins.mapAttrs (name: _: {
      source = create_sym "${dotfiles}/linux/${name}";
      recursive = true;
      force = true;
    }) (builtins.readDir "${dotfiles}/linux");
}
