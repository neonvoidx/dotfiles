CopyFile /etc/NetworkManager/system-connections/Wired\ connection\ 1.nmconnection 600
CopyFile /etc/bluetooth/main.conf
CopyFile /etc/default/limine
CopyFile /etc/environment
CopyFile /etc/fstab
CopyFile /etc/greetd/config.toml
CopyFile /etc/hostname
CopyFile /etc/issue
CopyFile /etc/mkinitcpio.conf
CopyFile /etc/pacman.conf
CopyFile /etc/pacman.d/hooks/50-pacman-list.hook
CopyFile /etc/systemd/system.conf
CreateLink /etc/systemd/system/display-manager.service /usr/lib/systemd/system/greetd.service
CopyFile /etc/udev/rules.d/60-streamdeck.rules
CopyFile /etc/vconsole.conf
