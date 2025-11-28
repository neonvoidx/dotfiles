{ config, pkgs, lib, ... }:

{
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          # 5 minutes
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          # 10 minutes
          timeout = 600;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on && brightnessctl -r";
        }
        {
          # 1 hour
          timeout = 3600;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
