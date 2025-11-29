{ config, pkgs, lib, ... }:

let
  # Path to dotfiles repository - adjust if your dotfiles are in a different location
  dotfilesPath = "${config.home.homeDirectory}/dotfiles";
in
{
  gtk.enable = true;

  # Symlink gtk configs from dotfiles
  xdg.configFile."gtk-2.0" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/linux/.config/gtk-2.0";
    recursive = true;
  };

  xdg.configFile."gtk-3.0" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/linux/.config/gtk-3.0";
    recursive = true;
  };

  xdg.configFile."gtk-4.0" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/linux/.config/gtk-4.0";
    recursive = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk";
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
