#!/bin/bash
# @ AI Context: Prerequisites step. Installs the minimum tooling the rest of
# the wizard depends on: package manager, git, gh, zsh, stow, whiptail.
# On mac: Homebrew + brew packages. On linux: apt update + apt install.
# Idempotent: skips anything already present.

_install_mac_prereqs() {
    if ! command -v brew >/dev/null 2>&1; then
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
            >> "$LOG_FILE" 2>&1 || return 1
    fi

    # newt provides whiptail on mac
    local pkgs=(git gh zsh stow newt)
    local missing=()
    for p in "${pkgs[@]}"; do
        case "$p" in
            newt) command -v whiptail >/dev/null 2>&1 || missing+=("$p") ;;
            *)    command -v "$p" >/dev/null 2>&1 || missing+=("$p") ;;
        esac
    done

    if [ "${#missing[@]}" -gt 0 ]; then
        log_info "brew install ${missing[*]}"
        brew install "${missing[@]}" >> "$LOG_FILE" 2>&1 || return 1
    fi
}

_install_linux_prereqs() {
    local pkgs
    if [ "${SETUP_PROFILE:-}" = "server" ]; then
        # Minimal — no whiptail (use plain prompts), no gh (deferred & optional),
        # no build-essential / python3-pip (no language runtimes on SBC).
        pkgs=(git zsh stow curl wget unzip)
    else
        pkgs=(git gh zsh stow whiptail curl wget unzip build-essential python3-pip)
    fi
    _spin "apt update" _sudo apt update -y || return 1
    _spin "apt install ${pkgs[*]}" _sudo apt install -y "${pkgs[@]}" || return 1
}

step_prereqs() {
    case "$OS_NAME" in
        mac)   _install_mac_prereqs ;;
        linux) _install_linux_prereqs ;;
    esac
}
