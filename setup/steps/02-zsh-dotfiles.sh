#!/bin/bash
# @ AI Context: Stow all public dotfile packages and set zsh as default shell.
# Runs early so the user has a working terminal environment before the long
# brew/apt apps install kicks off in the background.

step_zsh_dotfiles() {
    cd "$DOTFILES_DIR" || return 1
    chmod +x stow-all.sh
    log_info "Running stow-all.sh"
    ./stow-all.sh >> "$LOG_FILE" 2>&1 || return 1

    # Switch login shell to zsh if not already
    local current_shell zsh_path
    current_shell="$(basename "$SHELL")"
    zsh_path="$(command -v zsh)"

    if [ "$current_shell" != "zsh" ] && [ -n "$zsh_path" ]; then
        if tui_yesno "Default shell" "Set zsh ($zsh_path) as your default login shell?"; then
            # Ensure zsh is in /etc/shells (mac sometimes needs this for brew zsh)
            if ! grep -Fxq "$zsh_path" /etc/shells 2>/dev/null; then
                echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
            fi
            sudo chsh -s "$zsh_path" "$USER" >> "$LOG_FILE" 2>&1 || \
                chsh -s "$zsh_path" >> "$LOG_FILE" 2>&1 || \
                log_err "chsh failed; set shell manually"
        fi
    fi
}
