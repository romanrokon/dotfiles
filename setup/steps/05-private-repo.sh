#!/bin/bash
# @ AI Context: Clone (or update) the private dotfiles repo via HTTPS and stow
# its packages. HTTPS chosen so a fresh machine without SSH keys can still
# clone — gh is set up as git credential helper in the previous step.

step_private_repo() {
    chmod +x "$DOTFILES_DIR/setup.private.sh"
    "$DOTFILES_DIR/setup.private.sh"
}
