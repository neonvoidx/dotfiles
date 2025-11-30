{ config, lib, pkgs, ... }:

{
  imports = [ 
    ../../modules/linux-common.nix
  ];

  networking.hostName = "void";
  networking.networkmanager.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  boot.kernelParams = [
    "video=DP-1:3440x1440@144"
    "video=DP-2:3440x1440@144"
    "video=HDMI-A-1:2560x1440@144"
  ];
  hardware.amdgpu.initrd.enable = true;
  environment.variables.AMD_VULKAN_ICD = "RADV";
}
