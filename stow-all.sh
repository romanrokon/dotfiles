#!/bin/bash
# @ AI Context: Automation script to stow all packages in the stow/ directory.
# This script ensures that every subdirectory in stow/ is linked to the home directory.

# @ AI Context: Dry-run guard. The wizard exports DRY_RUN=1 to skip real work.
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "[DRY] stow-all.sh would stow all packages in $HOME/.dotfiles/stow"
    exit 0
fi

DOTFILES_DIR="$HOME/.dotfiles"
STOW_DIR="$DOTFILES_DIR/stow"

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo "Error: GNU Stow is not installed."
    exit 1
fi

echo "Automatically stowing all packages from $STOW_DIR..."

cd "$DOTFILES_DIR" || exit

# Iterate through all directories in stow/
for pkg in stow/*/; do
    # Remove trailing slash and 'stow/' prefix to get package name
    pkg_name=$(basename "$pkg")
    
    echo "Stowing: $pkg_name"
    
    # Pro-tip: Before stowing, we look for top-level hidden directories in the package
    # and ensure they exist in $HOME. This prevents Stow from symlinking the directory 
    # itself (folding) and instead symlinks the files inside.
    find "$STOW_DIR/$pkg_name" -maxdepth 2 -name ".*" -type d | while read -r dir; do
        target_dir="$HOME/${dir#$STOW_DIR/$pkg_name/}"
        if [ ! -d "$target_dir" ] && [ "$target_dir" != "$HOME/." ] && [ "$target_dir" != "$HOME/.." ]; then
            # echo "Creating target directory: $target_dir"
            mkdir -p "$target_dir"
        fi
    done

    # Run stow
    stow -d stow -t "$HOME" "$pkg_name"
done

echo "All packages stowed successfully."
