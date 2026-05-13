#!/bin/bash
# @ AI Context: Modernized macOS setup script using GNU Stow.
# This script is idempotent and uses dynamic symlinking for all components.

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

# @ AI Context: Dynamic Stow symlinking
echo "Applying dotfiles..."
cd "$HOME/.dotfiles" || exit
./stow-all.sh

# @ AI Context: Universal Agent Bridge
# Links Claude to the unified ~/.agents Source of Truth.
# Gemini and Copilot naturally respect ~/.agents/skills.
echo "Setting up universal agent bridges..."
mkdir -p "$HOME/.claude"
ln -sf "$HOME/.agents/skills" "$HOME/.claude/skills"
ln -sf "$HOME/.agents/agents" "$HOME/.claude/agents"
ln -sf "$HOME/.agents/hooks" "$HOME/.claude/hooks"

# iterm settings
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$HOME/.config/iterm2"
defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

# Install dependencies from apps lists
echo "Installing apps from brew.txt..."
xargs brew install < apps/brew.txt

# Specialized linking for Yazi dependencies
echo "Linking Yazi dependencies..."
brew link ffmpeg-full imagemagick-full -f --overwrite

# Setup NVM
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
fi

# Finalizing
echo "Setup complete. Please restart your terminal."
