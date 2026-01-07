# Dotfiles

## About

This contains my dotfiles for Linux and Mac. Uses GNU stow.

## Installing

### Main Method for just dotfiles

 1. `chmod +x stow.sh && stow.sh`
    - This will first pull all submodules recursively:
      - nvim config
      - pics (wallpapers)
      - vault (obsidian vault, *private* will only pull for me)
    - It will then run `stow common` followed by detecting OS and running appropriate `stow mac` or `stow linux`
  
### For full system setup, check `ansible folder`


# Nix
I've moved to Nix, you can see my nix setup here https://github.com/neonvoidx/nix
