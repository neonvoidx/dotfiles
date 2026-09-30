# Homebrew Packages

- <https://brew.sh/>
  - `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- To restore from any directory: `brew bundle install --file ~/dotfiles/mac/.config/brew/Brewfile --no-upgrade`
- Omit `--no-upgrade` to also upgrade installed packages.
- Private Oracle taps require working corporate SSH access and verified host keys.
- If public GitHub taps fail with `Permission denied (publickey)` due to a global HTTPS-to-SSH rewrite, tap with an explicit HTTPS port, e.g. `brew tap acsandmann/tap https://github.com:443/acsandmann/homebrew-tap`, then rerun the restore. This leaves global Git configuration unchanged.
- To dump to Brewfile in cd: `brew bundle dump`
- To force cleanup based on Brewfile: `brew bundle --force cleanup`
- To update: `brew update` -> `brew outdated` -> `brew upgrade`

## Completing an interactive restore

Run the restore command in Terminal so app installers can prompt for your Mac administrator password. Do not run `brew` itself with `sudo`. If Oracle taps fail host-key verification, finish corporate SSH setup and verify the host keys before retrying.

If npm Corepack conflicts with Homebrew's `yarn`, install Corepack without its package-manager shims, then link only its own command:

```sh
npm install --global --bin-links=false --ignore-scripts --force corepack
ln -s ../lib/node_modules/corepack/dist/corepack.js /opt/homebrew/bin/corepack
```

These paths assume Apple Silicon Homebrew's default prefix. The `--force` flag bypasses npm's early executable-collision check; `--bin-links=false` preserves the existing Yarn links. Skip `ln` if the Corepack link already exists. Enabling Corepack's Yarn shims later requires resolving ownership of the Yarn command first.

Verify the restore with `brew bundle check --file ~/dotfiles/mac/.config/brew/Brewfile --no-upgrade --verbose`.
