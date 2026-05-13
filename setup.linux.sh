#!/bin/bash
# @ AI Context: Modernized Linux setup script using GNU Stow.
# This script uses dynamic package detection and symlinking.

# Required packages to continue
sudo apt update
sudo apt install -y zsh curl wget unzip stow build-essential python3-pip

# @ AI Context: Dynamic Stow symlinking
echo "Applying dotfiles..."
cd "$HOME/.dotfiles" || exit
chmod +x stow-all.sh
./stow-all.sh

# System tweaks
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sed -i "s/NoDisplay=true/NoDisplay=false/g" /etc/xdg/autostart/*.desktop

# Disable tracker miner fs (if applicable)
sudo systemctl mask tracker-store.service tracker-miner-fs.service tracker-miner-rss.service tracker-extract.service tracker-miner-apps.service tracker-writeback.service 2>/dev/null

# Install NodeJS with nvm
if [ ! -d "$HOME/.nvm" ]; then
    PROFILE=/dev/null bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash'
fi

# Better cd (zoxide)
command -v zoxide &> /dev/null || curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Repositories for Neovim etc.
sudo add-apt-repository ppa:neovim-ppa/stable -y
sudo add-apt-repository ppa:appimagelauncher-team/stable -y

# Install all apps from list
xargs --arg-file apps/apt.txt sudo apt install -y

# Install Cargo apps
if command -v cargo &> /dev/null; then
    echo "Installing Cargo apps from cargo.txt..."
    xargs cargo install < apps/cargo.txt
else
    echo "Cargo is not installed. Skipping cargo apps."
fi

# Finalizing
echo "Setup complete. Switching to zsh..."
exec zsh --login
