#!/bin/bash
echo "Installing ansible and stow..."
paru -S ansible stow
echo "Installing ansible galaxy requirements..."
ansible-galaxy collection install -r requirements.yml
echo "Running ansible playbook..."
ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass -vvv
