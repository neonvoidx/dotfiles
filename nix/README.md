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
        ├── kitty.nix            # Symlinks kitty config from dotfiles
        ├── zsh.nix              # Sources zshrc from dotfiles
        ├── bash.nix             # Sources bashrc from dotfiles
        ├── git.nix              # Sources gitconfig from dotfiles
        ├── btop.nix             # Symlinks btop config from dotfiles
        ├── bat.nix              # Symlinks bat config from dotfiles
        ├── lsd.nix              # Symlinks lsd config from dotfiles
        ├── yazi.nix             # Symlinks yazi config from dotfiles
        ├── lazygit.nix          # Symlinks lazygit config from dotfiles
        ├── mpv.nix              # Symlinks mpv config from dotfiles
        ├── hyprland.nix         # Symlinks hypr config from dotfiles
        ├── hypridle.nix         # Uses hypridle config from hypr directory
        ├── hyprlock.nix         # Uses hyprlock config from hypr directory
        ├── gtk.nix              # Symlinks GTK configs from dotfiles
        ├── fastfetch.nix        # Symlinks fastfetch config from dotfiles
        ├── mangohud.nix         # Symlinks MangoHud config from dotfiles
        └── walker.nix           # Symlinks walker config from dotfiles
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

### Dotfiles Sourcing

Home Manager modules **symlink/source the original dotfiles** from the `common/` and `linux/` directories instead of generating configurations inline. This means:

- Your existing dotfiles remain the source of truth
- Changes to dotfiles are immediately reflected
- No duplication of configuration
- Easy to maintain and update

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

### Home Manager Modules

Home Manager is configured to:
1. **Symlink configuration directories** from `common/.config/` and `linux/.config/`
2. **Source shell configs** (`.zshrc`, `.bashrc`, `.gitconfig`) from `common/`
3. **Only manage configurations**, not install applications

All applications are installed via the NixOS system configuration in `modules/nixos/packages.nix`.

### Hyprland

The configuration symlinks the entire `linux/.config/hypr` directory, which includes:
- `hyprland.conf` - Main Hyprland configuration
- `hypridle.conf` - Idle management
- `hyprlock.conf` - Lock screen configuration
- `scripts/` - Helper scripts

### Shell Configuration

Shell configurations are sourced from your existing dotfiles:
- `.zshrc` from `common/.zshrc`
- `.bashrc` from `common/.bashrc`
- `.bash_profile` from `common/.bash_profile`

ZSH plugins (pure, zsh-vi-mode, fzf-tab) are still managed by Home Manager.

## Customization

### Adding New Hosts

1. Create a new directory under `hosts/`
2. Copy and modify `configuration.nix`, `hardware-configuration.nix`, and `home.nix`
3. Add the new host to `flake.nix`

### Adding Home Manager Modules

1. Create a new `.nix` file in `modules/home-manager/`
2. Import it in `hosts/default/home.nix`
3. Use `xdg.configFile` or `home.file` to symlink from dotfiles

### Package Management

System packages are managed in `modules/nixos/packages.nix`. Add or remove packages there.

## Notes

- Home Manager symlinks to the original dotfiles in `common/` and `linux/` directories
- The dotfiles are the single source of truth for all configurations
- The hardware configuration is a placeholder - run `nixos-generate-config` on your target system
- Some Arch-specific packages may need NixOS alternatives
