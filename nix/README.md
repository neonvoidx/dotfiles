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
        ├── kitty.nix            # Kitty terminal with Eldritch theme
        ├── zsh.nix              # ZSH with plugins, aliases, functions
        ├── bash.nix             # Bash configuration
        ├── git.nix              # Git with delta, aliases
        ├── btop.nix             # System monitor with Eldritch theme
        ├── bat.nix              # Cat replacement with Eldritch theme
        ├── lsd.nix              # Ls replacement with custom colors
        ├── yazi.nix             # File manager with Eldritch theme
        ├── lazygit.nix          # Git UI with commitizen integration
        ├── mpv.nix              # Media player with Wayland/Vulkan
        ├── hyprland.nix         # Hyprland window manager
        ├── hypridle.nix         # Idle daemon configuration
        ├── hyprlock.nix         # Lock screen with Eldritch theme
        ├── gtk.nix              # GTK/Qt theming
        ├── fastfetch.nix        # System info display
        ├── mangohud.nix         # Gaming overlay
        └── walker.nix           # Application launcher
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

### Native Nix Configuration

All modules use **native Home Manager program options** instead of multiline strings or symlinks. This provides:

- Type-checked configuration values
- Better error messages
- IDE support and autocompletion
- Proper Nix module composition

Example from `kitty.nix`:
```nix
programs.kitty = {
  enable = true;
  settings = {
    foreground = "#ebfafa";
    background = "#212337";
    cursor = "#37f499";
  };
};
```

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

Each application has its own module with:
- Program-specific settings using Home Manager's program options
- Theme colors configured inline
- Shell integrations enabled where applicable

### Hyprland

Full Hyprland configuration including:
- Window manager settings (gaps, borders, animations)
- Keybindings (SUPER as mod key)
- Startup applications
- Hypridle for screen timeout
- Hyprlock for screen locking

### Shell Configuration

ZSH configuration includes:
- Pure prompt with Eldritch colors
- fzf-tab for completions
- zsh-vi-mode for vim-style editing
- Useful aliases and functions
- Integration with zoxide, fzf, thefuck

## Customization

### Adding New Hosts

1. Create a new directory under `hosts/`
2. Copy and modify `configuration.nix`, `hardware-configuration.nix`, and `home.nix`
3. Add the new host to `flake.nix`

### Adding Home Manager Modules

1. Create a new `.nix` file in `modules/home-manager/`
2. Import it in `hosts/default/home.nix`
3. Use `programs.<name>` options where available

### Package Management

System packages are managed in `modules/nixos/packages.nix`. Add or remove packages there.

## Notes

- All configurations use native Nix settings instead of multiline strings
- The hardware configuration is a placeholder - run `nixos-generate-config` on your target system
- Some Arch-specific packages may need NixOS alternatives
