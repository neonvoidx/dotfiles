{ config, lib, pkgs, ... }:

{
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 7d";
  };
  
  boot.loader.systemd-boot.configurationLimit = 10;
}
