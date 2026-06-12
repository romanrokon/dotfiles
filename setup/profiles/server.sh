#!/bin/bash
# @ AI Context: Server / SBC profile definition. Sourced by stow-all.sh and the
# step files when SETUP_PROFILE=server. Single source of truth for which
# packages, scripts, and behaviors apply on a headless Linux box.

# Stow packages allowed on server. Everything else under stow/ is skipped.
# Order matters only for log readability.
SERVER_STOW_PACKAGES=(
    zsh
    tmux
    git
    ssh
    bin
    vim
    aria2
)

# Hostname default used by the summary step if /etc/hostname is generic.
SERVER_HOSTNAME_DEFAULT="server"

# Steps that should be no-ops on server (the step bodies guard themselves;
# this is documentation + a hook for future logic).
SERVER_SKIP_STEPS=(
    runtimes        # no NVM / cargo on server
)

# Features stripped from the zsh package on server (guarded inside .zshrc).
SERVER_DISABLED_FEATURES=(
    nvm
    fzf-tab
    fzf-git
    forgit
    gemini-chat
    desktop-aliases     # Arc, claude, code, cursor, tailscale GUI
)
