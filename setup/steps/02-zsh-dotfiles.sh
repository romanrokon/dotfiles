#!/bin/bash
# @ AI Context: Stow all public dotfile packages and set zsh as default shell.
# Runs early so the user has a working terminal environment before the long
# brew/apt apps install kicks off in the background.

_clone_zsh_plugin() {
    local repo=$1 dest=$2
    [ -d "$dest" ] && return 0
    log_info "Cloning $repo → $dest"
    git clone --depth=1 "$repo" "$dest" >> "$LOG_FILE" 2>&1
}

step_zsh_dotfiles() {
    cd "$DOTFILES_DIR" || return 1
    chmod +x stow-all.sh
    log_info "Running stow-all.sh"
    ./stow-all.sh >> "$LOG_FILE" 2>&1 || return 1

    # Third-party zsh plugins not in oh-my-zsh / brew / apt — cloned to known paths.
    local omz_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    _clone_zsh_plugin https://github.com/Aloxaf/fzf-tab.git "$omz_custom/plugins/fzf-tab"
    _clone_zsh_plugin https://github.com/junegunn/fzf-git.sh.git "$HOME/.fzf-git"
    # forgit is in brew on macOS but not apt — clone so Linux gets it too
    _clone_zsh_plugin https://github.com/wfxr/forgit.git "$HOME/.forgit"

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
