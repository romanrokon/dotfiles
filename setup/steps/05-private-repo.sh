#!/bin/bash
# @ AI Context: Clone (or update) the private dotfiles repo via HTTPS and stow
# its packages. HTTPS chosen so a fresh machine without SSH keys can still
# clone — gh is set up as git credential helper in the previous step.

step_private_repo() {
    # Server profile: only attempt private repo if gh is authed. Non-fatal
    # otherwise — the SBC may not need pihole.env etc.
    if [ "${SETUP_PROFILE:-}" = "server" ]; then
        if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
            log_info "Skipping private repo (server profile, gh not authed)."
            return 0
        fi
    fi
    chmod +x "$DOTFILES_DIR/setup.private.sh"
    "$DOTFILES_DIR/setup.private.sh"
}
