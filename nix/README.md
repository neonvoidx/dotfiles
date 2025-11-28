# NixOS Configuration with Home Manager

This directory contains NixOS configuration using Flakes with modular structure and Home Manager for user-level application configurations.

## Structure

```
nix/
├── flake.nix                    # Main flake definition
├── hosts/
│   └── default/
│       ├── configuration.nix    # NixOS system configuration
│       ├── hardware-configuration.nix  # Hardware-specific settings
│       └── home.nix             # Home Manager entry point
└── modules/
    ├── nixos/
    │   └── packages.nix         # System packages from pkglist.txt
    └── home-manager/
        ├── kitty.nix            # Kitty terminal configuration
        ├── zsh.nix              # Zsh shell configuration
        ├── bash.nix             # Bash shell configuration
        ├── git.nix              # Git configuration
        ├── btop.nix             # Btop system monitor
        ├── bat.nix              # Bat (cat replacement) configuration
        ├── lsd.nix              # Lsd (ls replacement) configuration
        ├── yazi.nix             # Yazi file manager configuration
        ├── lazygit.nix          # Lazygit configuration
        ├── mpv.nix              # Mpv media player configuration
        ├── hyprland.nix         # Hyprland window manager
        ├── hypridle.nix         # Hypridle screen idle daemon
        ├── hyprlock.nix         # Hyprlock screen locker
        ├── gtk.nix              # GTK theming
        ├── fastfetch.nix        # Fastfetch system info
        ├── mangohud.nix         # MangoHud gaming overlay
        └── walker.nix           # Walker application launcher
```

## Usage

### First-time Setup

1. Generate hardware configuration on your target system:
   ```bash
   sudo nixos-generate-config --show-hardware-config > nix/hosts/default/hardware-configuration.nix
   ```

2. Update `nix/hosts/default/configuration.nix`:
   - Set your hostname
   - Set your timezone
   - Adjust user configuration

3. Build and switch to the new configuration:
   ```bash
   cd nix
   sudo nixos-rebuild switch --flake .#default
   ```

### Home Manager Only

If you want to use only Home Manager on a non-NixOS system:

```bash
nix run home-manager/master -- switch --flake .#neonvoid
```

### Updating

```bash
nix flake update
sudo nixos-rebuild switch --flake .#default
```

## Key Features

### Eldritch Theme
All configurations use the [Eldritch](https://github.com/eldritch-theme) color scheme:
- Background: `#212337`
- Foreground: `#ebfafa`
- Green: `#37f499`
- Cyan: `#04d1f9`
- Purple: `#a48cf2`
- Pink: `#f265b5`
- Red: `#f16c75`
- Yellow: `#f1fc79`
- Orange: `#f7c67f`
- Comment: `#7081d0`

### Home Manager Modules

Home Manager is configured to **only manage application configurations**, not install applications. All applications are installed via the NixOS system configuration in `modules/nixos/packages.nix`.

### Hyprland

The configuration includes a full Hyprland setup with:
- Custom keybindings (SUPER as mod key)
- Eldritch themed borders and colors
- Animation configurations
- Multi-monitor support
- Hypridle for screen timeout
- Hyprlock for screen locking

### Shell Configuration

Both Zsh and Bash are configured with:
- Aliases for common commands
- Integration with fzf, zoxide, thefuck
- Custom functions for yazi, ffmpeg helpers
- Pure prompt for Zsh

## Customization

### Adding New Hosts

1. Create a new directory under `hosts/`
2. Copy and modify `configuration.nix`, `hardware-configuration.nix`, and `home.nix`
3. Add the new host to `flake.nix`

### Adding Home Manager Modules

1. Create a new `.nix` file in `modules/home-manager/`
2. Import it in `hosts/default/home.nix`

### Package Management

System packages are managed in `modules/nixos/packages.nix`. Add or remove packages there.

## Notes

- All configurations are generated from scratch based on the dotfiles in `common/` and `linux/` directories
- No external configuration files are sourced - everything is inline in the Nix files
- The hardware configuration is a placeholder - run `nixos-generate-config` on your target system
- Some Arch-specific packages may need NixOS alternatives
