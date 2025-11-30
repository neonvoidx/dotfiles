{ config, lib, pkgs, ... }:

{
  # Enable automounting for network drives
  services.rpcbind.enable = true;
  systemd.mounts = [{
    type = "nfs";
    mountConfig = { Options = "noatime"; };
    what = "192.168.86.6:/volume1";
    where = "/mnt/synology";
  }];

  systemd.automounts = [{
    wantedBy = [ "multi-user.target" ];
    automountConfig = { TimeoutIdleSec = "600"; };
    where = "/mnt/synology";
  }];

  # Ensure mount point exists
  systemd.tmpfiles.rules = [ "d /mnt/network-drive 0755 root root" ];

  # Install utilities for network file systems
  environment.systemPackages = with pkgs; [ nfs-utils cifs-utils ];
}
