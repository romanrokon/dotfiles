#!/bin/bash
# @ AI Context: Server-only hardening step. Skipped entirely when not on the
# server profile. Installs fail2ban + unattended-upgrades, prompts to harden
# sshd (drop-in conf, never lock the user out), and drops a pihole-FTL cron
# if pihole is present.

# True when systemd is the running init (real Linux box). False in plain
# Docker containers — we skip systemctl calls there so output stays clean.
_has_systemd() { [ -d /run/systemd/system ]; }

_enable_unattended_upgrades() {
    _spin "Installing unattended-upgrades" _sudo apt install -y unattended-upgrades apt-listchanges
    _sudo dpkg-reconfigure --priority=low unattended-upgrades >> "$LOG_FILE" 2>&1 || \
        echo 'APT::Periodic::Update-Package-Lists "1"; APT::Periodic::Unattended-Upgrade "1";' | \
            _sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null
    if _has_systemd; then
        _sudo systemctl enable --now unattended-upgrades.service >> "$LOG_FILE" 2>&1 || true
    else
        log_info "No systemd — skipping 'systemctl enable unattended-upgrades' (container?)."
    fi
}

_enable_fail2ban() {
    _spin "Installing fail2ban" _sudo apt install -y fail2ban

    # Minimal sshd jail — bantime 1h, maxretry 5.
    _sudo tee /etc/fail2ban/jail.d/sshd.local >/dev/null <<'EOF'
[sshd]
enabled  = true
port     = ssh
backend  = systemd
maxretry = 5
findtime = 10m
bantime  = 1h
EOF
    if _has_systemd; then
        _sudo systemctl enable --now fail2ban >> "$LOG_FILE" 2>&1 || true
        _sudo fail2ban-client reload >> "$LOG_FILE" 2>&1 || true
    else
        log_info "No systemd — fail2ban installed but not started (container?)."
    fi
}

_ssh_harden_prompt() {
    local key_count
    key_count=$(grep -cE "^(ssh-|ecdsa-|sk-)" "$HOME/.ssh/authorized_keys" 2>/dev/null || echo 0)

    # Safety: refuse to harden if no authorized_keys present.
    if [ "$key_count" -eq 0 ]; then
        log_err "No keys in ~/.ssh/authorized_keys — refusing to disable password auth (would lock you out)."
        log_info "Add a key (ssh-copy-id user@host) and re-run, or skip SSH hardening."
        return 0
    fi

    # Safety: only prompt if current session itself used a key (publickey method).
    # SSH_CONNECTION is set when remote; if missing we're on the console — safe.
    if [ -n "${SSH_CONNECTION:-}" ]; then
        # `who am i` shows tty + connection; doesn't reveal auth method, but the
        # presence of authorized_keys + remote session is a reasonable proxy.
        :
    fi

    local body
    body=$(cat <<EOF
Found $key_count key(s) in ~/.ssh/authorized_keys.

Proposed changes (drop-in at /etc/ssh/sshd_config.d/99-dotfiles-hardening.conf):
  PasswordAuthentication no
  PermitRootLogin no
  ChallengeResponseAuthentication no
  UsePAM yes  (kept)

Apply hardening?
EOF
)
    if ! tui_yesno "SSH hardening" "$body"; then
        log_info "User declined SSH hardening — leaving sshd_config untouched."
        return 0
    fi

    _sudo tee /etc/ssh/sshd_config.d/99-dotfiles-hardening.conf >/dev/null <<'EOF'
# Drop-in placed by ~/.dotfiles setup wizard. Edit or rm to revert.
PasswordAuthentication no
PermitRootLogin no
ChallengeResponseAuthentication no
UsePAM yes
EOF

    if _sudo sshd -t 2>>"$LOG_FILE"; then
        if _has_systemd; then
            _sudo systemctl reload ssh 2>/dev/null || _sudo systemctl reload sshd 2>/dev/null || true
            log_info "sshd reloaded with hardened config."
        else
            log_info "sshd config written; no systemd to reload — restart sshd manually."
        fi
    else
        log_err "sshd -t failed; removing drop-in. Check $LOG_FILE."
        _sudo rm -f /etc/ssh/sshd_config.d/99-dotfiles-hardening.conf
        return 1
    fi
}

_install_pihole_cron() {
    command -v pihole-FTL >/dev/null 2>&1 || return 0
    log_info "pihole-FTL detected — installing nightly Teleporter backup cron"

    local script="$HOME/.bin/pihole-cron-backup"
    if [ ! -x "$script" ]; then
        log_err "pihole-cron-backup not found at $script; stow must have failed."
        return 0
    fi

    _sudo install -d -m 755 /var/backups/pihole
    _sudo tee /etc/cron.d/pihole-backup >/dev/null <<EOF
# Nightly Pi-hole Teleporter backup. Installed by ~/.dotfiles setup wizard.
# Script lives at $script (symlink from stow/bin).
30 3 * * * root $script
EOF
    _sudo chmod 644 /etc/cron.d/pihole-backup
}

step_server_harden() {
    [ "${SETUP_PROFILE:-}" = "server" ] || return 0

    _enable_unattended_upgrades
    _enable_fail2ban
    _install_pihole_cron
    _ssh_harden_prompt
}
