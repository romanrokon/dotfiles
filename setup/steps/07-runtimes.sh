#!/bin/bash
# @ AI Context: Install NVM (Node version manager) and any Cargo apps listed
# in apps/cargo.txt. Cargo step is skipped if rustup/cargo isn't installed.

step_runtimes() {
    if [ ! -d "$HOME/.nvm" ]; then
        log_info "Installing NVM..."
        PROFILE=/dev/null bash -c \
            'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash' \
            >> "$LOG_FILE" 2>&1 || return 1
    fi

    local cargo_list="$DOTFILES_DIR/apps/cargo.txt"
    if command -v cargo >/dev/null 2>&1 && [ -f "$cargo_list" ]; then
        log_info "cargo install from $cargo_list"
        xargs cargo install < "$cargo_list" >> "$LOG_FILE" 2>&1 || \
            log_err "Some cargo installs failed; see log"
    else
        log_info "cargo not present or no cargo.txt; skipping cargo apps"
    fi
}
