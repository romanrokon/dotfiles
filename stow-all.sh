#!/bin/bash
set -euo pipefail
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

# @ AI Context: Profile-aware stow. If SETUP_PROFILE is set and a matching
# profile file exists, source it and iterate only SERVER_STOW_PACKAGES (or
# equivalent). Otherwise fall back to "stow everything under stow/" behavior.
PROFILE_FILE="$DOTFILES_DIR/setup/profiles/${SETUP_PROFILE:-}.sh"
if [ -n "${SETUP_PROFILE:-}" ] && [ -f "$PROFILE_FILE" ]; then
    # shellcheck source=/dev/null
    source "$PROFILE_FILE"
    echo "Profile: $SETUP_PROFILE — stowing whitelisted packages only."
fi

echo "Automatically stowing packages from $STOW_DIR..."

cd "$DOTFILES_DIR" || exit

# Build list of packages to stow.
if [ "${SETUP_PROFILE:-}" = "server" ] && [ ${#SERVER_STOW_PACKAGES[@]} -gt 0 ]; then
    pkg_list=("${SERVER_STOW_PACKAGES[@]/#/stow/}")
    # Append trailing slash to mimic the glob form below.
    pkg_list=("${pkg_list[@]/%//}")
else
    pkg_list=(stow/*/)
fi

# Iterate selected packages
for pkg in "${pkg_list[@]}"; do
    # Remove trailing slash and 'stow/' prefix to get package name
    pkg_name=$(basename "$pkg")

    # Skip if the package directory does not exist (server whitelist may
    # reference a package that hasn't been created yet).
    [ -d "$STOW_DIR/$pkg_name" ] || { echo "Skipping missing package: $pkg_name"; continue; }

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
