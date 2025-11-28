{ config, pkgs, lib, ... }:

{
  gtk = {
    enable = true;
    
    theme = {
      name = "adw-gtk3";
      package = pkgs.adw-gtk3;
    };
    
    iconTheme = {
      name = "Tela-circle-dracula-dark";
      package = pkgs.tela-circle-icon-theme;
    };
    
    cursorTheme = {
      name = "catppuccin-mocha-sapphire-cursors";
      package = pkgs.catppuccin-cursors.mochaSapphire;
      size = 24;
    };
    
    font = {
      name = "Adwaita Sans";
      size = 11;
    };

    gtk2.extraConfig = ''
      gtk-toolbar-style=GTK_TOOLBAR_ICONS
      gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
      gtk-button-images=0
      gtk-menu-images=0
      gtk-enable-event-sounds=1
      gtk-enable-input-feedback-sounds=0
      gtk-xft-antialias=1
      gtk-xft-hinting=1
      gtk-xft-hintstyle=hintslight
      gtk-xft-rgba=rgb
    '';

    gtk3 = {
      extraConfig = {
        gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
        gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
        gtk-button-images = 0;
        gtk-menu-images = 0;
        gtk-enable-event-sounds = 1;
        gtk-enable-input-feedback-sounds = 0;
        gtk-xft-antialias = 1;
        gtk-xft-hinting = 1;
        gtk-xft-hintstyle = "hintslight";
        gtk-xft-rgba = "rgb";
        gtk-application-prefer-dark-theme = 1;
      };
      
      extraCss = ''
        /* Custom GTK3 CSS */
        decoration {
          border-radius: 8px;
        }
      '';
    };

    gtk4 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
      
      extraCss = ''
        /* Custom GTK4 CSS */
        window {
          border-radius: 8px;
        }
      '';
    };
  };

  # dconf settings for GTK applications
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3";
      icon-theme = "Tela-circle-dracula-dark";
      cursor-theme = "catppuccin-mocha-sapphire-cursors";
      cursor-size = 24;
      font-name = "Adwaita Sans 11";
      document-font-name = "Adwaita Sans 11";
      monospace-font-name = "JetBrains Mono 11";
    };
    
    "org/gnome/desktop/wm/preferences" = {
      theme = "adw-gtk3";
    };
  };

  # Qt theming to match GTK
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };
}
