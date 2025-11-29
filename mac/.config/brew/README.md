# Homebrew Packages

- <https://brew.sh/>
  - `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- To restore from Brewfile: `brew bundle --file Brewfile`
- To dump to Brewfile in cd: `brew bundle dump`
- To force cleanup based on Brewfile: `brew bundle --force cleanup`
- To update: `brew update` -> `brew outdated` -> `brew upgrade`
