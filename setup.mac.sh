#!/bin/bash
# @ AI Context: Modernized macOS setup script using GNU Stow.
# This script is idempotent and uses symlinking for all components.

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Install GNU Stow if missing
command -v stow &> /dev/null || brew install stow

# Disable accented keys popup
defaults write -g ApplePressAndHoldEnabled -bool false
# Make dock appear faster
defaults write com.apple.dock autohide-delay -float 0.1; defaults write com.apple.dock autohide-time-modifier -float 0.3; killall Dock
# Make hidden apps easier to identify in the dock
defaults write com.apple.Dock showhidden -bool TRUE && killall Dock

# @ AI Context: Stow symlinking for all packages
echo "Applying dotfiles via Stow..."
cd "$HOME/.dotfiles" || exit

# List of packages to stow
PACKAGES=(zsh vim nvim git husky iterm2 ssh bin config claude)

# Ensure target directories exist to prevent Stow from symlinking the parent directory
mkdir -p "$HOME/.ssh" "$HOME/.config" "$HOME/.bin" "$HOME/.claude"

stow -d stow -t "$HOME" "${PACKAGES[@]}"

# iterm settings
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$HOME/.config/iterm2"
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

# Install dependencies from apps lists
echo "Installing apps..."
xargs brew install < apps/brew.txt

# Setup NVM
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
fi

# Finalizing
echo "Setup complete. Please restart your terminal."
