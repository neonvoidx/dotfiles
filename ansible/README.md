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

### Initial Setup

```bash
# Make sure ~/keys.txt exists with your age key
# Then run the init script
./init.sh
```

### Run the entire playbook

```bash
ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass
```

### Run specific tasks

Use tags to run specific task groups:

```bash
# Run only dotfiles deployment
ansible-playbook -i inventory.yaml playbook.yaml --tags dotfiles --ask-become-pass

# Run only package installation
ansible-playbook -i inventory.yaml playbook.yaml --tags install_packages --ask-become-pass

# Run only system configuration
ansible-playbook -i inventory.yaml playbook.yaml --tags configure_system --ask-become-pass
```

### Run task files directly

You can run individual task files directly without going through the main playbook:

```bash
# Run configure_system tasks
ansible-playbook -i inventory.yaml tasks/configure_system.yaml --ask-become-pass -v

# Run dotfiles tasks
ansible-playbook -i inventory.yaml tasks/dotfiles.yaml --ask-become-pass -v

# Run any other task file
ansible-playbook -i inventory.yaml tasks/<task_file>.yaml --ask-become-pass -v
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

- `tasks/dotfiles.yaml` - Deploys dotfiles with stow, decrypts SSH keys with sops/age, authenticates GitHub CLI
- `tasks/install_paru.yaml` - Installs paru AUR helper
- `tasks/update_system.yaml` - Updates system packages including AUR packages
- `tasks/install_packages.yaml` - Installs packages from repos and AUR
- `tasks/setup_services.yaml` - Configures greetd, systemd services, pacman hooks
- `tasks/configure_system.yaml` - Sets shell, kernel parameters, mounts /games partition

## Configuration

- `inventory.yaml` - Defines localhost as the target
- `playbook.yaml` - Main playbook that orchestrates all tasks

## Notes

- The playbook is designed to run locally on the Arch system
- Most tasks require sudo/root privileges
- Some services (hypridle, gnome-keyring) run in user scope
