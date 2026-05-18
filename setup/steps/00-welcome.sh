#!/bin/bash
# @ AI Context: Welcome step. Shows what the wizard will do and asks for go-ahead.

step_welcome() {
    local body
    body="Dotfiles setup wizard ($OS_NAME).

Steps:
  1. Install prerequisites (brew/apt, git, gh, zsh, stow, whiptail)
  2. Stow public dotfiles + set zsh as default shell
  3. Kick off apps install in background
  4. Authenticate with GitHub (gh auth login)
  5. Clone + stow private dotfiles repo
  6. Apply OS tweaks
  7. Install NVM + Cargo apps
  8. Wait for background apps install
  9. Final summary

State persisted in $STATE_FILE — safe to re-run.
Log: $LOG_FILE

Continue?"
    tui_yesno "Dotfiles Setup Wizard" "$body" || { log_info "User declined at welcome."; exit 0; }
}
