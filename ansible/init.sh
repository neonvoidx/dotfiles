#!/bin/bash

echo "Installing ansible and stow..."
paru -S ansible stow
echo "Installing ansible galaxy requirements..."
ansible-galaxy collection install -r requirements.yml
if [ ! -f ~/keys.txt ]; then
  echo "Error: ~/keys.txt not found. Please create your age key first."
  exit 1
fi
echo "Running ansible playbook..."
SOPS_AGE_KEY_FILE=~/keys.txt ansible-playbook -i inventory.yaml playbook.yaml --ask-become-pass -vvv
