{ pkgs, inputs, lib, ... }: {
  # install package only on Linux systems
  environment.systemPackages = lib.mkIf pkgs.stdenv.isLinux (with pkgs;
    [ inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default ]);
}
