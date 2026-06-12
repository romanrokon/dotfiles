#!/bin/bash
# @ AI Context: OS-specific tweaks. Mac: defaults writes for dock + key repeat.
# Linux: vm.swappiness, NoDisplay tweaks, tracker miner mask.

_tweaks_mac() {
    defaults write -g ApplePressAndHoldEnabled -bool false
    defaults write com.apple.dock autohide-delay -float 0.1
    defaults write com.apple.dock autohide-time-modifier -float 0.3
    defaults write com.apple.Dock showhidden -bool TRUE
    killall Dock 2>/dev/null || true

    # Spotlight indexing — opinionated off. Raycast is the launcher; mds_stores
    # churn is a known heat/RAM source. Reversible via `spotlight-on`.
    if tui_yesno "Spotlight" "Disable Spotlight indexing? (Raycast unaffected. Re-enable with: spotlight-on)"; then
        _sudo mdutil -a -i off || true
        _sudo mdutil -E / || true
    fi
}

_tweaks_linux() {
    # Swappiness
    if ! grep -q "vm.swappiness=10" /etc/sysctl.conf 2>/dev/null; then
        echo "vm.swappiness=10" | _sudo tee -a /etc/sysctl.conf >/dev/null
    fi

    if [ "${SETUP_PROFILE:-}" = "server" ]; then
        _tweaks_linux_server
        return
    fi

    # Desktop-only — no autostart .desktop entries or tracker-miner services on a server.
    # Show all autostart entries
    _sudo sed -i "s/NoDisplay=true/NoDisplay=false/g" /etc/xdg/autostart/*.desktop 2>/dev/null || true
    # Mask tracker miner
    _sudo systemctl mask \
        tracker-store.service tracker-miner-fs.service tracker-miner-rss.service \
        tracker-extract.service tracker-miner-apps.service tracker-writeback.service \
        2>/dev/null || true
}

_tweaks_linux_server() {
    # Server profile tweaks. Conservative — only sysctl and journald.

    # vfs_cache_pressure 50 — keep inode/dentry cache longer on slow SD storage.
    if ! grep -q "vm.vfs_cache_pressure" /etc/sysctl.conf 2>/dev/null; then
        echo "vm.vfs_cache_pressure=50" | _sudo tee -a /etc/sysctl.conf >/dev/null
    fi

    # Cap journald disk usage so logs don't fill the microSD.
    if [ -d /etc/systemd/journald.conf.d ] || _sudo mkdir -p /etc/systemd/journald.conf.d 2>/dev/null; then
        _sudo tee /etc/systemd/journald.conf.d/99-dotfiles.conf >/dev/null <<'JNL'
[Journal]
SystemMaxUse=200M
SystemKeepFree=200M
SystemMaxFileSize=20M
JNL
        # Skip on non-systemd (containers).
        [ -d /run/systemd/system ] && _sudo systemctl restart systemd-journald 2>/dev/null || true
    fi

    _sudo sysctl --system >> "${LOG_FILE:-/dev/null}" 2>&1 || true
}

step_os_tweaks() {
    if ! tui_yesno "OS tweaks" "Apply $OS_NAME OS tweaks (dock/key repeat or sysctl/tracker)?"; then
        return 0
    fi
    case "$OS_NAME" in
        mac)   _tweaks_mac ;;
        linux) _tweaks_linux ;;
    esac
}
