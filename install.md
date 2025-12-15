# Steps

# Pre install
1. Clear secure boot keys

# Install OS
2. Install CachyOS
3. cachy-chroot into system:
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
1. git clone https://github.com/neonvoidx/dotfiles
2. paru -S ansible stow  # pre ansible run dependencies
6. ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass -vvv

# CHECK THESE ISSUES AND COUMENT
pipewire-jack conflicted with jack2?

# ADD TO PLAYBOOK
add /games mount to fstab
streamcontroller service?
anyway to declaratively setup steam and storage, and default proton version, etc?
install stow # add to ansible post ansible install and dotfile clone
get secrets for github, ssh keys etc
stow dotfiles # add to ansible ^
systemctl disable ufw # add to ansible in services setup task
chsh -s /bin/zsh neonvoid # change to zsh shell for neonvoid
Add kernel params for amdgpu -> TODO
spicetify-cli setup
vconsole colors
set gnome-keyring auto login
sops and ages for credentials, ssh, github, spotify, firefox profile, vesktop profile, gnome keyring
Thunderbird setup accounts automatically

# spicetify
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
spicetify backup apply
spicetify apply?
Go to marketplace inside spotify -> backup restore -> restore from json file in ~/.config/spicetify/marketplace.json
