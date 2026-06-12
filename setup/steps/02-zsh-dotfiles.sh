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

_clone_zsh_file() {
    local url=$1 dest=$2
    [ -f "$dest" ] && return 0
    log_info "Fetching $url → $dest"
    mkdir -p "$(dirname "$dest")"
    curl -fsSL "$url" -o "$dest" >> "$LOG_FILE" 2>&1
}

_install_oh_my_zsh() {
    [ -d "$HOME/.oh-my-zsh" ] && return 0
    # --unattended skips chsh + the welcome shell. KEEP_ZSHRC=yes preserves our stowed .zshrc.
    _do_omz_install() {
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
            "" --unattended
    }
    _spin "Installing oh-my-zsh" _do_omz_install
    unset -f _do_omz_install
}

_install_p10k() {
    local omz_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    _clone_zsh_plugin https://github.com/romkatv/powerlevel10k.git "$omz_custom/themes/powerlevel10k"
}

_install_common_omz_plugins() {
    local omz_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    _clone_zsh_plugin https://github.com/zsh-users/zsh-autosuggestions       "$omz_custom/plugins/zsh-autosuggestions"
    _clone_zsh_plugin https://github.com/zsh-users/zsh-history-substring-search "$omz_custom/plugins/history-substring-search"
    _clone_zsh_plugin https://github.com/z-shell/F-Sy-H                       "$omz_custom/plugins/F-Sy-H"
    # auto-ls is a single .zsh file, not a repo — fetch directly.
    _clone_zsh_file https://raw.githubusercontent.com/desyncr/auto-ls/master/auto-ls.zsh \
        "$omz_custom/plugins/auto-ls.zsh"
}

step_zsh_dotfiles() {
    cd "$DOTFILES_DIR" || return 1
    chmod +x stow-all.sh
    log_info "Running stow-all.sh"
    ./stow-all.sh >> "$LOG_FILE" 2>&1 || return 1

    # Persist the active profile so .zshrc can read it for runtime guards.
    mkdir -p "$HOME/.config"
    echo "${SETUP_PROFILE:-desktop}" > "$HOME/.config/setup-profile"

    # oh-my-zsh + plugins the stowed .zshrc references. Required on every profile.
    _install_oh_my_zsh
    _install_p10k
    _install_common_omz_plugins

    # fzf-tab is small and only needs fzf — useful on server too.
    local omz_custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    _clone_zsh_plugin https://github.com/Aloxaf/fzf-tab.git "$omz_custom/plugins/fzf-tab"

    if [ "${SETUP_PROFILE:-}" != "server" ]; then
        # Desktop-only extras (git fzf bindings, forgit, node tooling).
        _clone_zsh_plugin https://github.com/junegunn/fzf-git.sh.git "$HOME/.fzf-git"
        # forgit is in brew on macOS but not apt — clone so Linux gets it too
        _clone_zsh_plugin https://github.com/wfxr/forgit.git "$HOME/.forgit"
        # zsh-nvm + zsh-npm-scripts-autocomplete + pipenv plugin used by desktop .zshrc plugins list
        _clone_zsh_plugin https://github.com/lukechilds/zsh-nvm.git "$omz_custom/plugins/zsh-nvm"
        _clone_zsh_plugin https://github.com/zthxxx/zsh-npm-scripts-autocomplete.git \
            "$omz_custom/plugins/zsh-npm-scripts-autocomplete"
    fi

    # Switch login shell to zsh if not already
    local current_shell zsh_path
    current_shell="$(basename "$SHELL")"
    zsh_path="$(command -v zsh)"

    if [ "$current_shell" != "zsh" ] && [ -n "$zsh_path" ]; then
        if tui_yesno "Default shell" "Set zsh ($zsh_path) as your default login shell?"; then
            # Ensure zsh is in /etc/shells (mac sometimes needs this for brew zsh)
            if ! grep -Fxq "$zsh_path" /etc/shells 2>/dev/null; then
                echo "$zsh_path" | _sudo tee -a /etc/shells >/dev/null
            fi
            local _user="${USER:-$(id -un)}"
            _sudo chsh -s "$zsh_path" "$_user" >> "$LOG_FILE" 2>&1 || \
                chsh -s "$zsh_path" >> "$LOG_FILE" 2>&1 || \
                log_err "chsh failed; set shell manually"
        fi
    fi
}
