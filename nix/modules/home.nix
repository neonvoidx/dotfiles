{ config, pkgs, lib, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  create_sym = path: config.lib.file.mkOutOfStoreSymlink path;
  
  # Auto-import all .nix files from modules/config/
  configDir = ./config;
  configFiles = builtins.filter
    (file: lib.hasSuffix ".nix" file)
    (builtins.attrNames (builtins.readDir configDir));
  configModules = map (file: configDir + "/${file}") configFiles;
in {
  imports = configModules;

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
    github-copilot-cli
    nodejs_24
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
  # Exclude .config and .local from top-level to avoid conflicts with home-manager
  # home.file = builtins.mapAttrs (name: _: {
  #   source = create_sym "${dotfiles}/common/${name}";
  #   force = true;
  # })
  #     (builtins.removeAttrs (builtins.readDir "${dotfiles}/common") [ ".config" ])
  #     // builtins.mapAttrs (name: _: {
  #       source = create_sym "${dotfiles}/linux/${name}";
  #       force = true;
  #     })
  #     (builtins.removeAttrs (builtins.readDir "${dotfiles}/linux") [ ".config" ]);
  #
  #   # Symlink .config subdirectories individually to allow home-manager to manage its own files
  #   xdg.configFile = builtins.mapAttrs (name: _: {
  #     source = create_sym "${dotfiles}/common/.config/${name}";
  #     force = true;
  #   }) (builtins.readDir "${dotfiles}/common/.config") // builtins.mapAttrs
  #     (name: _: {
  #       source = create_sym "${dotfiles}/linux/.config/${name}";
  #       force = true;
  #     }) (builtins.readDir "${dotfiles}/linux/.config");
  # }
}
