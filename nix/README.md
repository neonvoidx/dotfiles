# NixOS Configuration

Modular NixOS and Home Manager configuration using flakes with automatic dotfile symlinking.

## Structure

```
nix/
├── flake.nix              # Main flake with mkHost helper
├── flake.lock             # Locked dependencies
├── hosts/                 # Host-specific configurations
│   ├── voidframe/
│   │   └── configuration.nix  # Desktop system config
│   └── void/
│       └── configuration.nix  # Laptop system config
└── modules/               # Shared modules
    ├── home.nix           # Home-manager config with auto-symlinking
    ├── noctalia.nix       # Noctalia shell (system-wide)
    ├── garbage-collection.nix  # Auto cleanup & boot entries
    ├── linux-common.nix   # Shared Linux system config
    └── fonts.nix          # Font packages
```

## Features

- **Automatic dotfile symlinking**: `home.nix` automatically symlinks files from `~/dotfiles/common` and `~/dotfiles/linux` (or `~/dotfiles/mac` on macOS)
- **Multi-host support**: Easy host configuration with `mkHost` helper
- **Garbage collection**: Automatic cleanup every 7 days, limits boot entries to 10
- **Noctalia shell**: Custom shell integrated system-wide
- **Silent boot**: Plymouth with connect theme

## Usage

### Build and Switch

```bash
# Desktop
sudo nixos-rebuild switch --flake ~/dotfiles/nix#voidframe

# Laptop
sudo nixos-rebuild switch --flake ~/dotfiles/nix#void
```

### Add a New Host

1. Add host configuration in `flake.nix`:
```nix
nixosConfigurations = {
  myhost = mkHost {
    hostname = "myhost";
    username = "neonvoid";
    homeDirectory = "/home/neonvoid";
  };
};
```

2. Create `hosts/myhost/configuration.nix` with system-specific settings

3. For shared Linux config, import `linux-common.nix`:
```nix
{ config, lib, pkgs, ... }: {
  imports = [ 
    /etc/nixos/hardware-configuration.nix 
    ../../modules/linux-common.nix
  ];
  
  networking.hostName = "myhost";
  # host-specific config...
}
```

## Dotfile Management

Dotfiles are automatically symlinked by `home.nix`:
- Place common dotfiles in `~/dotfiles/common/`
- Place Linux-specific dotfiles in `~/dotfiles/linux/`
- Place macOS-specific dotfiles in `~/dotfiles/mac/`

Files maintain their directory structure when symlinked to `~/.config/` and other locations.

## Modules

### linux-common.nix
Shared configuration for Linux systems:
- Bootloader (systemd-boot) with Plymouth
- Sound (PipeWire)
- Printing, Bluetooth, Power management
- Display manager (ly)
- Hyprland with XWayland
- Gaming (Steam, GameScope)

### garbage-collection.nix
- Daily garbage collection (7 day retention)
- Boot entry limit (10 generations)

### fonts.nix
Font packages:
- JetBrains Mono (with Nerd Font variant)
- Roboto

## Notes

- All hosts automatically include `noctalia.nix` and `garbage-collection.nix`
- `home.nix` is shared across all hosts but platform-specific dotfiles are conditionally symlinked
- Wallpapers are auto-cloned from `github.com/neonvoidx/pics` to `~/pics`
