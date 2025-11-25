# Dotfiles

## About

This contains my dotfiles for Linux and Mac. Uses GNU stow.

## Installing

### Main Method

 1. `chmod +x stow.sh && stow.sh`
    - This will first pull all submodules recursively:
      - nvim config
      - pics (wallpapers)
      - vault (obsidian vault, *private* will only pull for me)
    - It will then run `stow common` followed by detecting OS and running appropriate `stow mac` or `stow linux`

### Alternatively

#### All OS's

 1. Run `stow common`
 2. Then run the below based on OS

#### Linux

  1. Run `stow linux`

#### Mac

 1. Run `stow mac`
