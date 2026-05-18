#!/bin/bash
# @ AI Context: Kick off the heavy apps install (brew.txt / apt.txt) in the
# background. Step 08 (wait-bg) blocks on completion later. This lets gh auth
# happen concurrently while packages download.

_install_apps_mac() {
    local list="$DOTFILES_DIR/apps/brew.txt"
    [ -f "$list" ] || { log_info "No brew.txt; skipping"; return 0; }
    log_info "brew installing from $list"
    xargs brew install < "$list"
    # Yazi deps
    brew link ffmpeg-full imagemagick-full -f --overwrite 2>/dev/null || true
}

_install_apps_linux() {
    local list="$DOTFILES_DIR/apps/apt.txt"
    [ -f "$list" ] || { log_info "No apt.txt; skipping"; return 0; }
    # Add the PPAs the old script used
    sudo add-apt-repository -y ppa:neovim-ppa/stable
    sudo add-apt-repository -y ppa:appimagelauncher-team/stable
    sudo apt update -y
    xargs --arg-file "$list" sudo apt install -y
}

step_apps_bg() {
    case "$OS_NAME" in
        mac)   bg_start apps_install _install_apps_mac ;;
        linux) bg_start apps_install _install_apps_linux ;;
    esac
    log_info "Apps install running in background. Continuing wizard."
}
