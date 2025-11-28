{ config, pkgs, lib, ... }:

{
  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrains Mono";
      size = 16;
    };

    settings = {
      # Window settings
      background_opacity = "0.95";
      
      # Eldritch theme colors
      foreground = "#ebfafa";
      background = "#212337";
      selection_foreground = "#ebfafa";
      selection_background = "#bf4f8e";
      
      url_color = "#04d1f9";
      
      # Black
      color0 = "#21222c";
      color8 = "#7081d0";
      
      # Red
      color1 = "#f9515d";
      color9 = "#f16c75";
      
      # Green
      color2 = "#37f499";
      color10 = "#69F8B3";
      
      # Yellow
      color3 = "#e9f941";
      color11 = "#f1fc79";
      
      # Blue
      color4 = "#9071f4";
      color12 = "#a48cf2";
      
      # Magenta
      color5 = "#f265b5";
      color13 = "#FD92CE";
      
      # Cyan
      color6 = "#04d1f9";
      color14 = "#66e4fd";
      
      # White
      color7 = "#ebfafa";
      color15 = "#ffffff";
      
      # Cursor colors
      cursor = "#37f499";
      cursor_text_color = "#f8f8f2";
      
      # Tab bar colors
      active_tab_foreground = "#212337";
      active_tab_background = "#37f499";
      inactive_tab_foreground = "#04d1f9";
      inactive_tab_background = "#323449";
      
      # Marks
      mark1_foreground = "#212337";
      mark1_background = "#f9515d";
      
      # Splits/Windows
      active_border_color = "#a48cf2";
      inactive_border_color = "#212337";
    };

    extraConfig = ''
      # Diff colors
      foreground #ebfafa
      background #212337

      title_fg #ebfafa
      title_bg #212337

      margin_bg #323449
      margin_fg #ebfafa

      removed_bg #f16c75
      highlight_removed_bg #04d1f9
      removed_margin_bg #323449

      added_bg #37f499
      highlight_added_bg #37f499
      added_margin_bg #323449

      filler_bg #323449
      margin_filler_bg none

      hunk_margin_bg #323449
      hunk_bg #a48cf2

      search_bg #f1fc79
      search_fg #212337
      select_bg #f1fc79
      select_fg #212337
    '';
  };
}
