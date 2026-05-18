#!/bin/bash
# @ AI Context: Authenticate with GitHub via `gh auth login`. Skips if already
# authed. Needed before the next step clones the private dotfiles repo via
# HTTPS (gh acts as the credential helper).

step_gh_auth() {
    if ! command -v gh >/dev/null 2>&1; then
        log_err "gh not installed; prereqs step should have handled this"
        return 1
    fi

    if gh auth status >/dev/null 2>&1; then
        log_info "gh already authenticated; skipping login."
        return 0
    fi

    tui_msg "GitHub auth" "Next: 'gh auth login' will run interactively. Pick HTTPS as the git protocol so the private repo clone uses gh as a credential helper."
    # Interactive; gh handles its own TUI.
    gh auth login || return 1
    # Ensure gh is set up as git credential helper for https clones
    gh auth setup-git >> "$LOG_FILE" 2>&1 || true
}
