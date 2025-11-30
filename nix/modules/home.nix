{ config, pkgs, lib, ... }:
let
  dotfiles = "${config.home.homeDirectory}/dotfiles";
  create_sym = path: config.lib.file.mkOutOfStoreSymlink path;
  
  # Determine OS-specific directory
  osDir = if pkgs.stdenv.isDarwin then "mac" else "linux";
  
  # Function to recursively find all files in a directory
  findFiles = dir: 
    let
      path = "${dotfiles}/${dir}";
      contents = builtins.readDir path;
      
      processEntry = name: type:
        let
          fullPath = "${path}/${name}";
          relativePath = if dir == "common" || dir == osDir 
                        then name 
                        else "${dir}/${name}";
        in
          if type == "directory" then
            findFiles "${dir}/${name}"
          else if type == "regular" || type == "symlink" then
            [{ path = relativePath; source = fullPath; }]
          else
            [];
    in
      lib.flatten (lib.mapAttrsToList processEntry contents);
  
  # Get all files from common and OS-specific directories
  commonFiles = findFiles "common";
  osSpecificFiles = findFiles osDir;
  allFiles = commonFiles ++ osSpecificFiles;
  
  # Convert to home.file attribute set
  fileAttrs = builtins.listToAttrs (map (file: {
    name = file.path;
    value = { source = create_sym file.source; };
  }) allFiles);
in {
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
  
  # Symlink all dotfiles
  home.file = fileAttrs;

}
