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
        ├── kitty.nix            # Kitty terminal (symlinks common/.config/kitty)
        ├── zsh.nix              # ZSH (symlinks common/.zshrc)
        ├── bash.nix             # Bash (symlinks common/.bashrc)
        ├── git.nix              # Git (symlinks common/.gitconfig)
        ├── btop.nix             # System monitor (symlinks common/.config/btop)
        ├── bat.nix              # Cat replacement (symlinks common/.config/bat)
        ├── lsd.nix              # Ls replacement (symlinks common/.config/lsd)
        ├── yazi.nix             # File manager (symlinks common/.config/yazi)
        ├── lazygit.nix          # Git UI (symlinks common/.config/lazygit)
        ├── mpv.nix              # Media player (symlinks common/.config/mpv)
        ├── hyprland.nix         # Hyprland (symlinks linux/.config/hypr)
        ├── hypridle.nix         # Idle daemon (config in hypr symlink)
        ├── hyprlock.nix         # Lock screen (config in hypr symlink)
        ├── gtk.nix              # GTK theming (symlinks linux/.config/gtk-*)
        ├── fastfetch.nix        # System info (symlinks linux/.config/fastfetch)
        ├── mangohud.nix         # Gaming overlay (symlinks linux/.config/MangoHud)
        └── walker.nix           # Application launcher (symlinks linux/.config/walker)
```

## Design Philosophy

**Your existing dotfiles are the source of truth.** Home Manager modules simply symlink to your existing configuration files in `common/` and `linux/` directories. This means:

- Changes to your dotfiles are immediately reflected
- You can still use your dotfiles with stow or other tools
- NixOS just ensures the symlinks are in place

## Usage

### First-time Setup

1. Clone this dotfiles repo to `~/dotfiles`:
   ```bash
   git clone <your-dotfiles-repo> ~/dotfiles
   ```

2. Generate hardware configuration on your target system:
   ```bash
   sudo nixos-generate-config --show-hardware-config > ~/dotfiles/nix/hosts/default/hardware-configuration.nix
   ```

3. Update `nix/hosts/default/configuration.nix`:
   - Set your hostname
   - Set your timezone
   - Adjust user configuration

4. Build and switch to the new configuration:
   ```bash
   cd ~/dotfiles/nix
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

### Dotfile Symlinks

All modules use `mkOutOfStoreSymlink` to create symlinks to your existing dotfiles:

```nix
# Example from kitty.nix
xdg.configFile."kitty" = {
  source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/common/.config/kitty";
  recursive = true;
};
```

This approach:
- Keeps your existing dotfiles as the single source of truth
- Changes to dotfiles are immediately reflected
- Works alongside stow or other dotfile managers
- No need to rebuild NixOS when you change a dotfile

### Dotfile Locations

The modules expect your dotfiles to be at `~/dotfiles`. The symlinks are created as follows:

| Module | Target | Source |
|--------|--------|--------|
| kitty | `~/.config/kitty` | `~/dotfiles/common/.config/kitty` |
| zsh | `~/.zshrc` | `~/dotfiles/common/.zshrc` |
| bash | `~/.bashrc`, `~/.bash_profile` | `~/dotfiles/common/.bashrc`, `~/dotfiles/common/.bash_profile` |
| git | `~/.gitconfig`, `~/.gitconfig.local` | `~/dotfiles/common/.gitconfig`, `~/dotfiles/linux/.gitconfig.local` |
| btop | `~/.config/btop` | `~/dotfiles/common/.config/btop` |
| bat | `~/.config/bat` | `~/dotfiles/common/.config/bat` |
| lsd | `~/.config/lsd` | `~/dotfiles/common/.config/lsd` |
| yazi | `~/.config/yazi` | `~/dotfiles/common/.config/yazi` |
| lazygit | `~/.config/lazygit` | `~/dotfiles/common/.config/lazygit` |
| mpv | `~/.config/mpv` | `~/dotfiles/common/.config/mpv` |
| hyprland | `~/.config/hypr` | `~/dotfiles/linux/.config/hypr` |
| gtk | `~/.config/gtk-{2,3,4}.0` | `~/dotfiles/linux/.config/gtk-{2,3,4}.0` |
| fastfetch | `~/.config/fastfetch` | `~/dotfiles/linux/.config/fastfetch` |
| mangohud | `~/.config/MangoHud` | `~/dotfiles/linux/.config/MangoHud` |
| walker | `~/.config/walker` | `~/dotfiles/linux/.config/walker` |

### Shell Integrations

Even though config files are symlinked, some programs need shell integrations enabled:

```nix
# ZSH module enables these integrations
programs.fzf.enableZshIntegration = true;
programs.zoxide.enableZshIntegration = true;
programs.thefuck.enableZshIntegration = true;
```

## Customization

### Changing Dotfiles Path

If your dotfiles are in a different location, update the `dotfilesPath` in each module:

```nix
let
  dotfilesPath = "${config.home.homeDirectory}/my-dotfiles";
in
```

### Adding New Hosts

1. Create a new directory under `hosts/`
2. Copy and modify `configuration.nix`, `hardware-configuration.nix`, and `home.nix`
3. Add the new host to `flake.nix`

### Package Management

System packages are managed in `modules/nixos/packages.nix`. Add or remove packages there.

## Notes

- The hardware configuration is a placeholder - run `nixos-generate-config` on your target system
- Some Arch-specific packages may need NixOS alternatives
- Your dotfiles must be present at the expected path for symlinks to work
