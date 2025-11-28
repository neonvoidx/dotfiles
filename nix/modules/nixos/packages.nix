{ config, pkgs, lib, ... }:

{
  # System packages from pkglist.txt
  # Note: Some packages are Arch/CachyOS specific and may need alternatives
  environment.systemPackages = with pkgs; [
    # Base system
    coreutils
    bash-completion
    bc
    bind
    diffutils
    dmidecode
    dosfstools
    e2fsprogs
    efibootmgr
    efitools
    ethtool
    exfatprogs
    f2fs-tools
    hdparm
    hwinfo
    inetutils
    inotify-tools
    iptables-nft
    less
    logrotate
    lsb-release
    lsof
    lvm2
    man-db
    man-pages
    nano
    ntfs3g
    ntp
    pciutils
    pkgfile
    pv
    rsync
    sudo
    sysfsutils
    texinfo
    tree
    usbutils
    wget
    which
    unrar
    unzip

    # Development
    git
    git-lfs
    delta
    gh
    go
    rustup
    rust-analyzer
    python3
    pyenv
    uv
    nodejs
    yarn
    luarocks
    shellcheck
    cmake
    ninja

    # Terminal tools
    alacritty
    kitty
    neovim
    vim
    micro
    tmux

    # CLI utilities
    ripgrep
    fd
    fzf
    zoxide
    bat
    lsd
    btop
    htop
    glances
    duf
    fastfetch
    figlet
    toilet
    cmatrix
    chafa
    pastel
    thefuck
    trash-cli
    asciinema
    mediainfo

    # File managers
    yazi
    xfce.thunar
    xfce.thunar-archive-plugin
    xfce.thunar-media-tags-plugin
    xfce.thunar-volman
    xarchiver

    # Git tools
    lazygit

    # Network tools
    nmap
    masscan
    hashcat
    sqlmap
    networkmanager
    networkmanagerapplet
    dhcpcd
    dnsmasq
    iwd
    wireguard-tools
    openssh
    wget
    curl

    # Bluetooth
    bluez
    bluez-tools
    blueman

    # Audio/Video
    pipewire
    wireplumber
    pavucontrol
    easyeffects
    playerctl
    mpv
    vlc
    obs-studio
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav

    # Graphics/Display
    brightnessctl
    grim
    slurp
    swappy
    wl-clipboard
    cliphist

    # Wayland/Hyprland
    hyprland
    hyprlock
    hypridle
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    xwayland

    # Theming
    gtk3
    gtk4
    gnome-themes-extra
    adw-gtk3
    papirus-icon-theme
    nwg-look

    # Fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    font-awesome
    jetbrains-mono
    (nerdfonts.override { fonts = [ "JetBrainsMono" "Meslo" ]; })
    roboto
    inter
    liberation_ttf

    # Applications
    firefox-devedition
    thunderbird
    gimp
    blender
    godot_4
    obsidian
    calibre
    prusa-slicer
    steam
    gamescope
    mangohud
    vkbasalt
    protonup-qt

    # System utilities
    gnome-keyring
    seahorse
    udiskie
    upower
    power-profiles-daemon
    cups
    hplip
    snapper
    btrfs-progs

    # Security
    ufw
    opensc

    # Compression
    p7zip
    gzip
    bzip2
    xz
    zstd

    # Misc
    stow
    flatpak
    wine
    winetricks

    # Vulkan/GPU
    vulkan-tools
    vulkan-loader
    mesa
    amdvlk
    libva-utils

    # Spicetify (for Spotify customization)
    spicetify-cli
    spotify
  ];

  # Enable services that correspond to packages
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  services.printing.enable = true;

  programs.steam.enable = true;

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    font-awesome
    jetbrains-mono
    (nerdfonts.override { fonts = [ "JetBrainsMono" "Meslo" ]; })
    roboto
    inter
    liberation_ttf
  ];
}
