#!/bin/bash
# @ AI Context: Clones the private dotfiles repo (dotfiles-pvt) into
# ~/.dotfiles-private and stows all packages from it. Idempotent.
# Private repo holds secret-ish configs (ssh hosts, tokens, etc) that
# must NOT live in the public dotfiles repo.

set -e

# @ AI Context: Dry-run guard. The wizard exports DRY_RUN=1 to skip real work.
if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "[DRY] setup.private.sh would clone/pull dotfiles-pvt and stow it"
    exit 0
fi

PRIVATE_DIR="$HOME/.dotfiles-private"
# @ AI Context: HTTPS so fresh machines without SSH keys can clone. The wizard
# runs `gh auth setup-git` in the gh_auth step to make gh the git credential
# helper, so this clone succeeds without prompting for a password.
PRIVATE_REPO="https://github.com/romanrokon/dotfiles-pvt.git"

if ! command -v stow &> /dev/null; then
    echo "Error: GNU Stow not installed. Run main setup first."
    exit 1
fi

if [ ! -d "$PRIVATE_DIR/.git" ]; then
    echo "Cloning private dotfiles repo..."
    git clone "$PRIVATE_REPO" "$PRIVATE_DIR"
else
    echo "Updating private dotfiles repo..."
    git -C "$PRIVATE_DIR" pull --ff-only
fi

echo "Stowing private packages from $PRIVATE_DIR/stow..."
cd "$PRIVATE_DIR" || exit

for pkg in stow/*/; do
    pkg_name=$(basename "$pkg")
    echo "Stowing (private): $pkg_name"

    # Pre-create hidden target dirs so stow links files not folders
    find "$PRIVATE_DIR/stow/$pkg_name" -maxdepth 2 -name ".*" -type d | while read -r dir; do
        target_dir="$HOME/${dir#$PRIVATE_DIR/stow/$pkg_name/}"
        if [ ! -d "$target_dir" ] && [ "$target_dir" != "$HOME/." ] && [ "$target_dir" != "$HOME/.." ]; then
            mkdir -p "$target_dir"
        fi
    done

    stow -d stow -t "$HOME" "$pkg_name"
done

echo "Private dotfiles applied."
