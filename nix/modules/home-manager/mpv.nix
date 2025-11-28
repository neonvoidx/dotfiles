{ config, pkgs, lib, ... }:

{
  programs.mpv = {
    enable = true;
    config = {
      gpu-context = "waylandvk";
      vo = "gpu-next";
      gpu-api = "vulkan";
      target-colorspace-hint = true;
    };
  };
}
