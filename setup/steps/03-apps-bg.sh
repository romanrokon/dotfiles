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

# Install apt packages one at a time, tolerant of missing packages (different
# Debian/Ubuntu versions have different package availability — eza/lazygit are
# in Debian 13+ but not 12 main, etc.). Logs per-package outcome.
_apt_install_tolerant() {
    local list=$1
    local pkg
    local failed=()
    local ok=0
    # Count total packages for progress display.
    local total
    total=$(grep -cvE '^\s*(#|$)' "$list")
    local idx=0
    while IFS= read -r pkg; do
        pkg="${pkg%%#*}"
        pkg="${pkg// /}"
        [ -z "$pkg" ] && continue
        idx=$((idx + 1))
        if _spin "[$idx/$total] apt install $pkg" _sudo apt install -y "$pkg"; then
            ok=$((ok + 1))
        else
            failed+=("$pkg")
        fi
    done < "$list"
    log_info "apt install summary: $ok ok, ${#failed[@]} failed: ${failed[*]:-(none)}"
    if [ ${#failed[@]} -gt 0 ]; then
        printf "  ⚠ Failed to install: %s\n" "${failed[*]}"
    fi
}

# Pull eza upstream release binary when apt didn't provide it (Debian 12 etc.).
_install_eza_from_release() {
    command -v eza >/dev/null 2>&1 && return 0
    local arch tarball url tmp
    case "$(uname -m)" in
        x86_64)  arch="x86_64-unknown-linux-gnu" ;;
        aarch64|arm64) arch="aarch64-unknown-linux-gnu" ;;
        armv7l|armv7) arch="arm-unknown-linux-gnueabihf" ;;
        *) log_info "eza fallback: unsupported arch $(uname -m); skipping"; return 0 ;;
    esac
    tarball="eza_${arch}.tar.gz"
    url="https://github.com/eza-community/eza/releases/latest/download/${tarball}"
    tmp="$(mktemp -d)"

    _do_eza_fetch() {
        curl -fsSL "$url" -o "$tmp/$tarball" && \
            tar -xzf "$tmp/$tarball" -C "$tmp" && \
            _sudo install -m 755 "$tmp/eza" /usr/local/bin/eza
    }

    _spin "Downloading eza from GitHub release ($arch)" _do_eza_fetch
    rm -rf "$tmp"
    unset -f _do_eza_fetch
}

_install_lazygit_from_release() {
    command -v lazygit >/dev/null 2>&1 && return 0
    local arch tmp asset url version
    case "$(uname -m)" in
        x86_64)  arch="x86_64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l|armv7) arch="armv6" ;;
        *) log_info "lazygit fallback: unsupported arch $(uname -m); skipping"; return 0 ;;
    esac
    version=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" \
        | grep -oE '"tag_name":\s*"v[0-9.]+"' | grep -oE '[0-9.]+')
    [ -z "$version" ] && { log_err "lazygit: could not resolve latest version"; return 0; }
    asset="lazygit_${version}_Linux_${arch}.tar.gz"
    url="https://github.com/jesseduffield/lazygit/releases/latest/download/${asset}"
    tmp="$(mktemp -d)"

    _do_lazygit_fetch() {
        curl -fsSL "$url" -o "$tmp/$asset" && \
            tar -xzf "$tmp/$asset" -C "$tmp" lazygit && \
            _sudo install -m 755 "$tmp/lazygit" /usr/local/bin/lazygit
    }

    _spin "Downloading lazygit v${version} ($arch)" _do_lazygit_fetch
    rm -rf "$tmp"
    unset -f _do_lazygit_fetch
}

_install_apps_linux() {
    local list
    if [ "${SETUP_PROFILE:-}" = "server" ]; then
        list="$DOTFILES_DIR/apps/apt.server.txt"
        [ -f "$list" ] || { log_info "No apt.server.txt; skipping"; return 0; }
        log_info "apt install from $list (server profile — no PPAs, minimal set)"
        _sudo apt update -y >> "$LOG_FILE" 2>&1
        _apt_install_tolerant "$list"
        _install_eza_from_release
        _install_lazygit_from_release
        return
    fi

    list="$DOTFILES_DIR/apps/apt.txt"
    [ -f "$list" ] || { log_info "No apt.txt; skipping"; return 0; }
    # Add the PPAs the desktop script used
    _sudo add-apt-repository -y ppa:neovim-ppa/stable
    _sudo add-apt-repository -y ppa:appimagelauncher-team/stable
    _sudo apt update -y
    _apt_install_tolerant "$list"
}

step_apps_bg() {
    case "$OS_NAME" in
        mac)   bg_start apps_install _install_apps_mac ;;
        linux)
            # Server profile runs synchronously — no gh/private-repo to overlap
            # with, and the user benefits from visible spinner progress.
            if [ "${SETUP_PROFILE:-}" = "server" ]; then
                _install_apps_linux
                return
            fi
            bg_start apps_install _install_apps_linux
            ;;
    esac
    log_info "Apps install running in background. Continuing wizard."
}
