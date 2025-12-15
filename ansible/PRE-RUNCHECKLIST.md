# Steps

# Pre install OS

1. Clear secure boot keys

# Install OS

1. Install CachyOS (base no DE or WM)
2. cachy-chroot into system:
    - sbctl steps:
      - sbctl status # checks status of secure boot, should be in setup mode
      - sbctl create-keys # Creates keys
      - sbctl enroll-keys -m -f #enrolls keys and adds firmware and microsoft keys
      - sbctl verify # verify signed
      - sbctl-batch-sign # if no signed, run this (cachyOS only) to sign all, otherwise sbctl sign -s path/to/file
    - limine steps
      - limine-enroll-config
      - limine-update
      - limine-scan # for windows part, add windows boot loader

# Post Install OS -> Installing configuration for system and dotfiles

1. git clone <https://github.com/neonvoidx/dotfiles> ~neonvoid/dotfiles
2. paru -S ansible stow  # pre run depdencies
3. Ensure ages/sops `keys.txt` is downloaded (encryption key) and at `~/keys.txt`
4. `./init.sh`
    - This will run ansible playbook, full thing in README.md TLDR:
       - Installs chaotic aur mirror list
       - Upgrades system
       - Installs pacman and AUR packages from backup pkglist and pkglist_aur
       - Sets up services:
         - greetd w/ tuigreet
         - Stop job timeout set to 15sec so no slow ass shutdowns
         - disables ufw
         - Sets up pacman hooks to always push packages to backup list
      - Installs dotfiles:
         - Decrypts secrets with sops/ages:
           - ssh private key
        - Sets up github cli with ssh key
        - Sets up spicetify with Spotify
      - Configures other system things:
        - Sets kernel params in limine for amdgpu, display resolution, and regenerates limine
        - Mounts /games folder for UUID specific harddrive and adds to fstab
        - Configure vconsole font to terminus and colors with kernel hook then regens initramfs
