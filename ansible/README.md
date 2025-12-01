# Ansible Setup

Ansible playbook for automated Arch Linux system setup and configuration.

## What It Does

This playbook automates the following tasks:

1. **Install paru** - Installs the paru AUR helper if not already present
2. **Update system** - Ensures the system is up to date
3. **Install packages** - Installs packages from official Arch repos and AUR
4. **Setup services** - Configures and enables systemd services (ly display manager, ananicy-cpp, hypridle, gnome-keyring)

## Prerequisites

- Arch Linux system
- Ansible installed (`sudo pacman -S ansible`)
- Root/sudo access

## Configuration Variables

You can override default paths and settings using extra variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_chaotic_aur` | `true` | Enable/disable Chaotic AUR repository setup |
| `pkglist_file` | `~/dotfiles/linux/.config/pacman/pkglist.txt` | Path to package list file |
| `pkglist_aur_file` | `~/dotfiles/linux/.config/pacman/pkglist_aur.txt` | Path to AUR package list file |
| `ly_config_src` | `~/dotfiles/linux-sys/etc/ly/config.ini` | Path to ly config file |
| `pacman_hooks_src` | `~/dotfiles/linux-sys/etc/pacman.d/hooks/` | Path to pacman hooks directory |
| `screen_xres` | `3440` | Screen X resolution for ly display manager |
| `screen_yres` | `1440` | Screen Y resolution for ly display manager |

### Example with custom variables

```bash
ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass \
  -e "enable_chaotic_aur=false" \
  -e "pkglist_file=/home/user/configs/pkglist.txt" \
  -e "pkglist_aur_file=/home/user/configs/pkglist_aur.txt" \
  -e "ly_config_src=/home/user/configs/ly.ini" \
  -e "pacman_hooks_src=/home/user/configs/hooks/" \
  -e "screen_xres=1920" \
  -e "screen_yres=1080"
```

## How to Run

### Run the entire playbook

```bash
ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass
```

### Run specific tasks

Use tags or specify the task file directly:

```bash
# Run only package installation
ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass --tags install_packages

# Run specific task file
ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass --start-at-task "Install packages from Arch repo and AUR"
```

### Check what would change (dry-run)

```bash
ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass --check
```

### Verbose output

```bash
ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass -v   # or -vv, -vvv for more verbosity
```

## Task Files

- `tasks/install_paru.yaml` - Installs paru AUR helper
- `tasks/update_system.yaml` - Updates system packages including AUR packages
- `tasks/install_packages.yaml` - Installs packages from repos and AUR
- `tasks/setup_services.yaml` - Configures ly, ananicy-cpp, hypridle, gnome-keyring services

## Configuration

- `inventory.yaml` - Defines localhost as the target
- `playbook.yaml` - Main playbook that orchestrates all tasks

## Notes

- The playbook is designed to run locally on the Arch system
- Most tasks require sudo/root privileges
- Some services (hypridle, gnome-keyring) run in user scope
