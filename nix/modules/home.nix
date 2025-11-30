{ config, pkgs, lib, ... }:

let
  # Import all .nix files from dotfiles directory
  dotfilesDir = ./dotfiles;
  dotfilesModules = 
    if builtins.pathExists dotfilesDir
    then
      let
        entries = builtins.readDir dotfilesDir;
        nixFiles = lib.filterAttrs (name: type: type == "regular" && lib.hasSuffix ".nix" name) entries;
      in
        map (name: dotfilesDir + "/${name}") (builtins.attrNames nixFiles)
    else [];
in
{
  imports = dotfilesModules;
  home.username = "neonvoid";
  home.homeDirectory = "/home/neonvoid";
  home.stateVersion = "25.05";
  programs.git.enable = true;

  home.packages = with pkgs; [
    # Aliasing to firefox-developer-edition
    (writeScriptBin "firefox-developer-edition" ''
      exec ${firefox-devedition}/bin/firefox-devedition "$@"
    '')
    fastfetch
    firefox-devedition
    gh
    git
    github-copilot-cli
    nodejs_24
    proton-pass
    protonmail-bridge
    protonup-qt
    thunderbird
    tree-sitter
    yazi
  ];

}
