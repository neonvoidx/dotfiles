{ config, pkgs, lib, ... }:

{
  programs.hyprlock = {
    enable = true;
    
    settings = {
      # Eldritch colors
      "$eldritch-bg" = "212337";
      "$eldritch-green" = "37f499";
      "$eldritch-cyan" = "04d1f9";
      "$eldritch-purple" = "a48cf2";
      "$eldritch-pink" = "f265b5";
      "$eldritch-red" = "f16c75";

      general = {
        disable_loading_bar = false;
        hide_cursor = true;
        grace = 0;
        no_fade_in = false;
      };

      # Background for main monitor
      background = [
        {
          monitor = "";
          color = "rgb(33, 35, 55)";
          blur_passes = 1;
          blur_size = 1;
        }
      ];

      # Date and time container shape
      shape = [
        {
          monitor = "";
          size = "350, 200";
          color = "rgba(50, 52, 73, 0.8)";
          rounding = 15;
          border_size = 1;
          border_color = "rgb($eldritch-green) rgb($eldritch-cyan) 45deg";
          halign = "center";
          valign = "top";
          zindex = 0;
          position = "0, -20%";
        }
      ];

      # Time label
      label = [
        {
          monitor = "";
          text = "$TIME";
          color = "rgb(55, 244, 153)";
          shadow_passes = 1;
          shadow_size = 3;
          shadow_color = "rgb(33, 35, 55)";
          shadow_boost = 1.8;
          font_size = 80;
          font_family = "Roboto Bold";
          position = "0%, -20%";
          halign = "center";
          valign = "top";
          zindex = 1;
        }
        # Date label
        {
          monitor = "";
          text = ''cmd[update:1000] echo -e "$(date +"%d %b %y")"'';
          color = "rgb(4, 209, 249)";
          shadow_passes = 1;
          shadow_size = 3;
          shadow_color = "rgb(33, 35, 55)";
          shadow_boost = 1.8;
          font_size = 24;
          font_family = "Roboto Bold";
          halign = "center";
          valign = "top";
          position = "0%, -30%";
          zindex = 1;
        }
      ];

      # Avatar image
      image = [
        {
          monitor = "";
          path = "";  # Set your avatar path here
          border_size = 0;
          size = 360;
          shadow_passes = 1;
          shadow_size = 3;
          shadow_color = "rgb(33, 35, 55)";
          shadow_boost = 1.8;
          rounding = -1;
          rotate = 0;
          reload_time = -1;
          position = "0, 0";
          halign = "center";
          valign = "center";
        }
      ];

      # Password input field
      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = true;
          dots_text_format = "🐇️";
          outer_color = "rgb(164,140,242)";
          inner_color = "rgba(50, 52, 73, 0.8)";
          font_color = "rgb(55, 244, 153)";
          fade_on_empty = false;
          placeholder_text = ''<i><span foreground="##ebfafa80"> 🐇️ Follow the white rabbit...</span></i>'';
          hide_input = false;
          check_color = "rgb(242, 101, 181)";
          fail_color = "rgb(241, 108, 117)";
          position = "0%, -20%";
          halign = "center";
          valign = "center";
          rounding = -1;
        }
      ];
    };
  };
}
