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
        ├── dotfiles.nix         # All dotfile symlinks in one place
        ├── zsh.nix              # ZSH plugins and shell integrations
        ├── git.nix              # Git delta integration
        ├── hyprland.nix         # Hyprland wayland compositor
        ├── hypridle.nix         # Hypridle service
        ├── hyprlock.nix         # Hyprlock service
        ├── gtk.nix              # GTK/Qt theming
        └── *.nix                # Other program placeholders
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

### Consolidated Dotfiles Symlinking

All dotfile symlinks are defined in a single file: `modules/home-manager/dotfiles.nix`. This includes:

**Home directory files:**
- `.zshrc`, `.bashrc`, `.bash_profile` → from `common/`
- `.gitconfig`, `.gitconfig.local` → from `common/` and `linux/`

**XDG config directories:**
- `kitty`, `btop`, `bat`, `lsd`, `yazi`, `lazygit`, `mpv` → from `common/.config/`
- `hypr`, `gtk-*`, `fastfetch`, `MangoHud`, `walker` → from `linux/.config/`

This approach:
- Keeps all symlink definitions in one place for easy maintenance
- Your existing dotfiles remain the source of truth
- Changes to dotfiles are immediately reflected
- No duplication of configuration

### Program Modules

Individual program modules (`zsh.nix`, `git.nix`, `hyprland.nix`, etc.) focus on:
- Enabling programs/services via Home Manager
- Installing plugins (e.g., ZSH plugins)
- Configuring integrations (e.g., fzf, zoxide)

### Eldritch Theme
All original dotfiles use the [Eldritch](https://github.com/eldritch-theme) color scheme:
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

## Customization

### Adding New Dotfile Symlinks

Edit `modules/home-manager/dotfiles.nix` and add entries to:
- `home.file` for files in home directory
- `xdg.configFile` for files in `~/.config/`

### Adding New Hosts

1. Create a new directory under `hosts/`
2. Copy and modify `configuration.nix`, `hardware-configuration.nix`, and `home.nix`
3. Add the new host to `flake.nix`

### Package Management

System packages are managed in `modules/nixos/packages.nix`. Add or remove packages there.

## Notes

- All symlinks are consolidated in `modules/home-manager/dotfiles.nix`
- The dotfiles are the single source of truth for all configurations
- The hardware configuration is a placeholder - run `nixos-generate-config` on your target system
- Some Arch-specific packages may need NixOS alternatives
