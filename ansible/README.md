# Ansible Arch Linux Setup

This Ansible playbook automates the setup of Arch Linux systems with package management, AUR helper installation, and service configuration.

## Prerequisites

- Arch Linux system
- Ansible installed: `sudo pacman -S ansible`
- Python installed: `sudo pacman -S python`

## Structure

```
ansible/
├── ansible.cfg           # Ansible configuration
├── inventory.ini         # Inventory file (localhost)
├── playbook.yml         # Main playbook
├── vars/                # Variable files
│   ├── packages.yml     # Package lists
│   └── services.yml     # Service configurations
└── roles/               # Ansible roles
    ├── arch-packages/   # Official repo packages
    ├── paru-aur-helper/ # Install paru AUR helper
    ├── aur-packages/    # AUR package installation
    └── system-services/ # Systemd service management
```

## Usage

1. **Edit configuration files:**
   - `vars/packages.yml` - Add your official and AUR packages
   - `vars/services.yml` - Configure services to enable/disable

2. **Run the playbook:**
   ```bash
   ansible-playbook playbook.yml --ask-become-pass
   ```

3. **Run specific roles with tags:**
   ```bash
   # Only install official packages
   ansible-playbook playbook.yml --tags packages --ask-become-pass
   
   # Only install paru and AUR packages
   ansible-playbook playbook.yml --tags aur --ask-become-pass
   
   # Only manage services
   ansible-playbook playbook.yml --tags services --ask-become-pass
   ```

## Available Tags

- `packages` - Official Arch packages
- `aur` - AUR helper and packages
- `services` - Systemd services
- `update` - System updates
- `cleanup` - Cleanup tasks

## Roles

### arch-packages
Installs packages from official Arch repositories using pacman.

### paru-aur-helper
Installs paru, a modern AUR helper for managing AUR packages.

### aur-packages
Installs packages from the AUR using paru.

### system-services
Manages systemd services (enable, disable, start, stop, restart).

## Customization

- Add custom roles in the `roles/` directory
- Create additional variable files in `vars/`
- Modify `playbook.yml` to include new roles
- Add templates in `roles/<role-name>/templates/`
- Add static files in `roles/<role-name>/files/`

## Notes

- The playbook runs on localhost by default
- Sudo password required for privilege escalation
- Uncomment packages/services in vars files to use them
- All roles have comments for customization guidance
