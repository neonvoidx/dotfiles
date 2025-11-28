{ config, pkgs, lib, ... }:

{
  # MangoHud configuration
  programs.mangohud = {
    enable = true;
    
    settings = {
      # Layout
      legacy_layout = false;
      hud_compact = true;
      table_columns = 2;
      position = "top-left";
      
      # Appearance
      background_alpha = 0.2;
      round_corners = 10;
      background_color = "000000";
      font_file = "/usr/share/fonts/TTF/Roboto-Regular.ttf";
      font_size = 22;
      text_color = "F0F0F0";
      
      # GPU
      pci_dev = "0:03:00.0";
      gpu_text = "GPU";
      
      # CPU
      cpu_text = "CPU";
      
      # FPS
      fps = true;
      fps_text = "FPS";
      fps_metrics = "avg,0.01";
      fps_limit_method = "late";
      fps_limit = 0;
      fps_color_change = true;
      fps_color = "B22222,FDFD09,39F900";
      fps_value = "30,60";
      
      # HDR
      hdr = true;
      
      # Toggle keys
      toggle_hud = "Shift_R+F12";
      toggle_fps_limit = "Shift_L+F1";
      toggle_logging = "Shift_L+F2";
      
      # Logging
      output_folder = "${config.home.homeDirectory}";
      log_duration = 30;
      autostart_log = 0;
      log_interval = 100;
      
      # Blacklist applications
      blacklist = "zenity,protonplus,lsfg-vk-ui,bazzar,gnome-calculator,pamac-manager,lact,ghb,bitwig-studio,ptyxis,yumex";
    };
  };
}
