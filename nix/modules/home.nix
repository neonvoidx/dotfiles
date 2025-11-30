{ config, pkgs, lib, ... }:

let
    dotfiles = "${config.home.homeDirectory}/dotfiles";
    create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
    
    # Recursively find all files in a directory and create symlink mappings
    symlinkFiles = sourceDir: 
      let
        # Get all files recursively
        findFiles = dir: 
          let
            entries = builtins.readDir dir;
            processEntry = name: type:
              let path = "${dir}/${name}";
              in
                if type == "directory" then
                  findFiles path
                else if type == "regular" then
                  [ path ]
                else
                  [];
          in
            lib.flatten (lib.mapAttrsToList processEntry entries);
        
        files = findFiles sourceDir;
        
        # Convert absolute paths to relative paths for home.file
        makeSymlinkEntry = filePath:
          let
            # Remove the sourceDir prefix and leading slash to get relative path
            relativePath = lib.removePrefix "${sourceDir}/" filePath;
          in
            lib.nameValuePair relativePath {
              source = create_symlink filePath;
            };
      in
        builtins.listToAttrs (map makeSymlinkEntry files);
    
    # Determine which directories to symlink based on system
    commonFiles = symlinkFiles "${dotfiles}/common";
    platformFiles = if pkgs.stdenv.isLinux 
                    then symlinkFiles "${dotfiles}/linux"
                    else if pkgs.stdenv.isDarwin
                    then symlinkFiles "${dotfiles}/mac"
                    else {};
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

  # Symlink all dotfiles
  home.file = commonFiles // platformFiles;

}
