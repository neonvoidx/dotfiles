{ config, pkgs, lib, ... }:

let
    dotfiles = "${config.home.homeDirectory}/dotfiles";
    create_symlink = path: config.lib.file.mkOutOfStoreSymlink path;
    
    # Recursively find all files in a directory and create symlink mappings
    symlinkFiles = sourceDir: 
      let
        # Get all files recursively, only regular files not directories
        findFiles = dir: 
          let
            entries = builtins.readDir dir;
            processEntry = name: type:
              let path = "${dir}/${name}";
              in
                if type == "directory" then
                  findFiles path  # Recurse into directories but don't symlink them
                else if type == "regular" then
                  [ path ]  # Only collect regular files
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
    commonFiles = symlinkFiles "${dotfiles}/common"; # All common dotfiles
    # OS specific
    platformFiles = if pkgs.stdenv.isLinux 
                    then symlinkFiles "${dotfiles}/linux"
                    else if pkgs.stdenv.isDarwin
                    then symlinkFiles "${dotfiles}/mac"
                    else {};
in
{
  home.username = "neonvoid";
  home.homeDirectory = "/home/neonvoid";
  home.stateVersion = "25.05";
  programs.git.enable = true;

  home.packages = with pkgs; [
    # Aliasing to firefox-developer-edition
    (writeScriptBin "firefox-developer-edition" ''
      exec ${firefox-devedition}/bin/firefox-devedition "$@"
    '')
    cargo
    fastfetch
    firefox-devedition
    gcc
    gh
    git
    github-copilot-cli
    go
    gzip
    kitty
    lazygit
    neovim
    nodejs_24
    pay-respects
    proton-pass
    python314
    ripgrep
    ripgrep
    rustc
    tealdeer
    tree-sitter
    unzip
    wget
    yazi
    zoxide
  ];

  # Symlink all dotfiles
  home.file = commonFiles // platformFiles;

  home.activation.cloneWallpapers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PICS_DIR="${config.home.homeDirectory}/pics"
    if [ ! -d "$PICS_DIR" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone https://github.com/neonvoidx/pics.git "$PICS_DIR"
    else
      $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$PICS_DIR" pull
    fi
  '';

}
