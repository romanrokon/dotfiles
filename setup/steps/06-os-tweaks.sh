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
        sudo mdutil -a -i off || true
        sudo mdutil -E / || true
    fi
}

_tweaks_linux() {
    # Swappiness
    if ! grep -q "vm.swappiness=10" /etc/sysctl.conf 2>/dev/null; then
        echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf >/dev/null
    fi
    # Show all autostart entries
    sudo sed -i "s/NoDisplay=true/NoDisplay=false/g" /etc/xdg/autostart/*.desktop 2>/dev/null || true
    # Mask tracker miner
    sudo systemctl mask \
        tracker-store.service tracker-miner-fs.service tracker-miner-rss.service \
        tracker-extract.service tracker-miner-apps.service tracker-writeback.service \
        2>/dev/null || true
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
