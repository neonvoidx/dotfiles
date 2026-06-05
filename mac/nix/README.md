# Nix Packages

This is a regular Nix flake for a small set of user packages. It does not use nix-darwin or Home Manager.

## Outputs

- `.#nvim`: Neovim from `github:neonvoidx/nvim`.
- `.#comma`: `comma` from nixpkgs.
- `.#default`: a profile-installable bundle containing both packages.

## Install Nix

Install Nix in daemon mode:

```sh
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
```

Enable flakes for the first build if your Nix install does not already have them enabled:

```sh
mkdir -p ~/.config/nix
printf 'experimental-features = nix-command flakes\n' >> ~/.config/nix/nix.conf
```

Restart the shell after installing Nix so `nix` is on `PATH`.

## Use

```sh
nix profile install .#default
nix run .#nvim
nix develop
```
