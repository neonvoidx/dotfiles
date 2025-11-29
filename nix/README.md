# NixOS Configuration

Modular NixOS and Home Manager configuration with flakes.

## Structure

```
nix/
├── flake.nix              # Main flake with mkHost helper
├── flake.lock             # Locked dependencies
├── hosts/                 # Host-specific configurations
│   └── voidframe/
│       └── configuration.nix  # System config for voidframe
└── modules/               # Shared modules
    ├── home.nix           # Common home-manager config
    └── noctalia.nix       # Noctalia shell (system-wide)
```

## Usage

### Build and Switch
```bash
sudo nixos-rebuild switch --flake ~/dotfiles/nix#voidframe
```

### Add a New Host

The flake uses a `mkHost` helper function for easy multi-host configuration:

```nix
nixosConfigurations = {
  voidframe = mkHost {
    hostname = "voidframe";
    username = "neonvoid";
    homeDirectory = "/home/neonvoid";
  };
  
  laptop = mkHost {
    hostname = "laptop";
    username = "neonvoid";
    homeDirectory = "/home/neonvoid";
    # system = "x86_64-linux";  # optional, defaults to x86_64-linux
    # stateVersion = "25.05";   # optional, defaults to 25.05
  };
};
```

Then create `hosts/laptop/configuration.nix`.

## Adding Application Modules

To add per-application home-manager configuration:

1. Create a new module in `modules/`:
   ```bash
   # Example: modules/kitty.nix
   { pkgs, ... }: {
     programs.kitty = {
       enable = true;
       font.name = "JetBrains Mono";
       font.size = 16;
     };
   }
   ```

2. Import it in `modules/home.nix`:
   ```nix
   { config, pkgs, ... }: {
     imports = [
       ./kitty.nix
     ];
     # ... rest of config
   }
   ```

## Notes

- `home.nix` is shared across all hosts
- Each host has its own `configuration.nix` in `hosts/<hostname>/`
- `noctalia.nix` is applied system-wide to all hosts automatically
- The `mkHost` function handles all the boilerplate configuration
