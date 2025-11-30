{ config, lib, pkgs, ... }:

{
  imports = [ 
    ../../modules/linux-common.nix
  ];

  networking.hostName = "voidframe";
  networking.wireless.enable = true;
  networking.wireless.networks."LittyPitty".pskRaw =
    "654787ccc87bf9e3520e3cc82840cf1e3dd182a466e92a70d5f47ecd160501e0";
}
