# Steps

# Pre install

1. Clear secure boot keys

# Install OS

1. Install CachyOS
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

1. git clone <https://github.com/neonvoidx/dotfiles>
2. paru -S ansible stow  # pre ansible run dependencies
3. ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass -vvv

# ADD TO PLAYBOOK

anyway to declaratively setup steam and storage, and default proton version, etc?
Thunderbird setup accounts automatically
hyprcursor
