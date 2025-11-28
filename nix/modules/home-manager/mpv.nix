{ config, pkgs, lib, ... }:

{
  programs.mpv = {
    enable = true;
    
    config = {
      # GPU and rendering settings
      gpu-context = "waylandvk";
      vo = "gpu-next";
      gpu-api = "vulkan";
      target-colorspace-hint = true;
      
      # Quality settings
      profile = "high-quality";
      
      # Hardware decoding
      hwdec = "auto-safe";
      
      # Audio
      audio-pitch-correction = true;
      
      # Subtitles
      sub-auto = "fuzzy";
      sub-font = "JetBrains Mono";
      sub-font-size = 40;
      sub-border-size = 2;
      sub-shadow-offset = 1;
      sub-color = "#EBFAFA";
      sub-border-color = "#212337";
      sub-shadow-color = "#000000";
      
      # OSD
      osd-font = "JetBrains Mono";
      osd-font-size = 32;
      osd-color = "#EBFAFA";
      osd-border-color = "#212337";
      osd-border-size = 2;
      osd-duration = 2000;
      
      # Screenshots
      screenshot-format = "png";
      screenshot-high-bit-depth = true;
      screenshot-png-compression = 4;
      screenshot-directory = "~/Pictures/mpv";
      
      # Cache
      cache = true;
      demuxer-max-bytes = "1GiB";
      demuxer-max-back-bytes = "512MiB";
    };
    
    bindings = {
      # Navigation
      "LEFT" = "seek -5";
      "RIGHT" = "seek 5";
      "UP" = "seek 60";
      "DOWN" = "seek -60";
      
      # Volume
      "WHEEL_UP" = "add volume 2";
      "WHEEL_DOWN" = "add volume -2";
      
      # Playback speed
      "[" = "multiply speed 0.9091";
      "]" = "multiply speed 1.1";
      "{" = "multiply speed 0.5";
      "}" = "multiply speed 2.0";
      "BS" = "set speed 1.0";
      
      # Subtitles
      "j" = "cycle sub";
      "J" = "cycle sub down";
      
      # Audio
      "a" = "cycle audio";
      
      # Screenshot
      "s" = "screenshot";
      "S" = "screenshot video";
    };
  };
}
