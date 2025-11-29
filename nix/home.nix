{ config, pkgs, ...}:
let 
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  create_sym = path: config.lib.file.mkOutOfStoreSymlink path;
  configs = {
    easyeffects = "/linux/.config/easyeffects";
    fastfetch = "/linux/.config/fastfetch";
    hypr = "/linux/.config/hypr";
    # todo gtk
    mpv = "/linux/.config/mpv";
    mango = "/linux/.config/mango";
    MangoHud = "/linux/.config/MangoHud";
    niri = "/linux/.config/niri";
    noctalia = "/linux/.config/noctalia";
    pipewire = "/linux/.config/pipewire";
    scopebuddy = "/linux/.config/scopebuddy";
    Thunar = "/linux/.config/Thunar";
    walker = "/linux/.config/walker";
    wireplumber = "/linux/.config/wireplumber";
    bat = "/common/.config/bat";
    btop = "/common/.config/btop";
    kitty = "/common/.config/kitty";
    lazygit = "/common/.config/lazygit";
    lsd = "/common/.config/lsd";
    nvim = "/common/.config/nvim";
    spicetify = "/common/.config/spicetify";
    yazi = "/common/.config/yazi";
  };
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

    # source dotfiles repo
    xdg.configFile = builtins.mapAttrs (name: subpath: {
      source = create_sym "${dotfiles}${subpath}";
      recursive = true;
      force = true;
    }) configs;
    home.file.".gitconfig" = {
      source = "${dotfiles}/common/.gitconfig";
      force = true;
    };
    home.file.".gitconfig.local" =  {
      source ="${dotfiles}/linux/.gitconfig.local";
      force = true;
    };
    home.file.".face" = {
      source = "${dotfiles}/linux/.face";
      force=true;
    };
    home.file."pics" = {
      source = "${dotfiles}/linux/pics";
      force=true;
    };
    home.file.".zshrc" = {
      source = "${dotfiles}/common/.zshrc";
      force=true;
    };
    # TODO: how to setup firefox stuff
    # home.file.".mozilla/user.js" = {
    #   source = "${dotfiles}/common/.mozilla/user.js";
    #   force=true;
    # };
    # home.file.".mozilla/chrome" = {
    #   source = "${dotfiles}/common/.mozilla/chrome";
    #   force=true; 
    # };
}
