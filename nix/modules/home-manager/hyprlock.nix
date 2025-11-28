{ config, pkgs, lib, ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        immediate_render = true;
        hide_cursor = false;
        ignore_empty_input = true;
        text_trim = true;
        fail_timeout = 3000;
      };

      background = [
        {
          monitor = "";
          color = "rgb(33, 35, 55)";
          blur_passes = 1;
          blur_size = 1;
        }
      ];

      shape = [
        {
          monitor = "";
          size = "350, 200";
          color = "rgba(50, 52, 73, 0.8)";
          rounding = 15;
          border_size = 1;
          border_color = "rgb(37f499) rgb(04d1f9) 45deg";
          halign = "center";
          valign = "top";
          zindex = 0;
          position = "0, -20%";
        }
      ];

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

      input-field = [
        {
          monitor = "";
          size = "300, 50";
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.2;
          dots_center = true;
          outer_color = "rgb(164,140,242)";
          inner_color = "rgba(50, 52, 73, 0.8)";
          font_color = "rgb(55, 244, 153)";
          fade_on_empty = false;
          placeholder_text = "<i><span foreground=\"##ebfafa80\"> Follow the white rabbit...</span></i>";
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
