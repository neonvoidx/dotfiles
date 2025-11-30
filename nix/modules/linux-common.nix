{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ./fonts.nix
    inputs.hyprland.nixosModules.default
  ];

  # Bootloader
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    plymouth = {
      enable = true;
      theme = "connect";
      themePackages = with pkgs;
        [
          # By default we would install all themes
          (adi1090x-plymouth-themes.override {
            selected_themes = [ "connect" ];
          })
        ];
    };

    # Enable "Silent boot"
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "udev.log_priority=3"
      "rd.systemd.show_status=auto"
    ];
    # Hide the OS choice for bootloaders.
    # It's still possible to open the bootloader list by pressing any key
    # It will just not appear on screen unless a key is pressed
    loader.timeout = 0;
  };

  time.timeZone = "America/New_York";

  # Printing and hardware
  services.printing.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  # Prevent rfkill from softblocking bluetooth and wifi
  systemd.services.rfkill-unblock = {
    description = "Unblock rfkill devices";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock all";
    };
  };

  # Sound with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # User configuration
  users.users.neonvoid = {
    isNormalUser = true;
    description = "neonvoid";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };

  # Programs
  programs.firefox.enable = true;
  programs.zsh.enable = true;
  programs.hyprland = {
    enable = true;
    package =
      inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
    withUWSM = false;
  };

  nixpkgs.config.allowUnfree = true;

  # Gaming
  programs.steam.enable = true;
  programs.steam.gamescopeSession.enable = true;

  environment.systemPackages = with pkgs; [
    vesktop
    steam
    gpu-screen-recorder
    mangohud
    protonup-ng
    protonmail-bridge
    cliphist
    wl-clipboard
    wl-clip-persist
    hyprpolkitagent
    thunderbird
    nwg-look
    udiskie
    xdg-desktop-portal-hyprland
    gnome-keyring
    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-vcs-plugin
    xfce.thunar-archive-plugin
    xfce.thunar-media-tags-plugin
    grim
    slurp
    (pkgs.callPackage ./scopebuddy.nix { })
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS =
      "\${HOME}/.steam/root/compatibilitytools.d";
  };

  # Display manager
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation = "colormix";
      bigclock = true;
      clear_password = true;
    };
  };

  networking.firewall.enable = false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "25.05";
}
