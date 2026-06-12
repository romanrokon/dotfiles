# Server / SBC setup

Minimal dotfiles profile for headless Linux boxes — Raspberry Pi, Orange Pi, Debian VMs, anything that runs Pi-hole / a small service and stays on 24/7.

## What you get

| Category | Tools |
|---|---|
| Shell | `zsh` + minimal oh-my-zsh plugin set, p10k prompt |
| Multiplexer | `tmux` (Ghostty-flavored: mouse on, true color, vim nav, splits `\|` and `-`) |
| Editor | `vim` (full `nvim` skipped — too heavy for SBC) |
| Modern CLI | `fzf`, `fd-find`, `ripgrep`, `bat`, `eza`, `zoxide`, `ncdu`, `trash-cli`, `lazygit`, `jq` |
| System health | `htop`, `lm-sensors`, `smartmontools`, `iotop` |
| Security | `fail2ban` (sshd jail), `unattended-upgrades`, optional SSH hardening prompt |
| Pi-hole only | nightly Teleporter zip in `/var/backups/pihole/` (last 14 kept) |
| Cross-platform scripts | `cool` / `heat` (dispatch to `cooldown-linux` / `heatlog-linux`) |

## Bootstrap

```sh
sudo apt update && sudo apt install -y git
git clone https://github.com/r0mankon/dotfiles ~/.dotfiles
cd ~/.dotfiles
./setup.linux-server.sh
```

The shim exports `SETUP_PROFILE=server` and runs the same wizard as desktop. Steps that don't apply (NVM, cargo, GUI brew packages, fzf-tab plugin clones, Mac launchd, swiftbar/waybar/iterm2 packages) are skipped automatically.

## What the wizard does on server

| Step | Behavior on `SETUP_PROFILE=server` |
|---|---|
| 01 prereqs | Apt installs *minimal* set: `git zsh stow curl wget unzip`. No `gh`, no `whiptail`, no `build-essential`. |
| 02 zsh dotfiles | Stows only `zsh tmux git ssh bin vim aria2`. Writes `~/.config/setup-profile`. Skips fzf-tab / fzf-git.sh / forgit clones. |
| 03 apps | Uses `apps/apt.server.txt`. No PPAs added. |
| 04 gh auth | Optional prompt; defaults to skip on server. |
| 05 private repo | Only runs if gh authed; non-fatal otherwise. |
| 06 OS tweaks | `vm.swappiness=10`, `vm.vfs_cache_pressure=50`, `journald SystemMaxUse=200M`. No autostart / tracker-miner tweaks. |
| 06b server hardening | Installs + enables `fail2ban` + `unattended-upgrades`, prompts for SSH hardening, installs pihole cron if `pihole-FTL` present. |
| 07 runtimes | **Skipped entirely.** |

## SSH hardening — what it does, why, and recovery

When prompted "Disable password auth + root login? [Y/n]" with default Yes:

- Writes `/etc/ssh/sshd_config.d/99-dotfiles-hardening.conf` (drop-in — your main `sshd_config` is untouched) containing:
  ```
  PasswordAuthentication no
  PermitRootLogin no
  ChallengeResponseAuthentication no
  UsePAM yes
  ```
- Validates with `sshd -t` then `systemctl reload ssh`.
- Aborts pre-flight if `~/.ssh/authorized_keys` is empty — refuses to lock you out.

**Why disable password auth:** SSH brute-force is constant. Key-only auth requires an attacker to steal your private key file — vastly harder than guessing/leaking a password.

**Why disable root login:** Forces login as a normal user then `sudo`. Adds username unknown + audit trail + sudo password wall.

**If you get locked out:**

1. Physical/console access (HDMI + keyboard, or serial header on SBCs):
   ```sh
   sudo rm /etc/ssh/sshd_config.d/99-dotfiles-hardening.conf
   sudo systemctl reload ssh
   ```
2. Recovery boot (SD card flash):
   - On Raspberry Pi: edit `/boot/cmdline.txt` to add `init=/bin/bash` → boot → mount-rw → remove the drop-in.
   - On Orange Pi: similar via Armbian boot args.

Tailscale tip: SSH stays reachable on the tailnet regardless of public exposure. The risk we're hardening against is the *tailnet's* attack surface (compromised member device pivoting).

## Pi-hole backup model

- **Server-side cron** (`/etc/cron.d/pihole-backup`) — runs at 03:30 daily, dumps a Teleporter zip to `/var/backups/pihole/`, rotates last 14.
- **Mac-side launchd** (`com.rzman.pihole-backup` from the desktop profile) — runs Sundays 03:00, SSHes in and pulls a fresh zip to iCloud Drive.

Two independent backup paths. Lose the SD card → restore from iCloud. iCloud sync broken → restore from `/var/backups`.

## Verify after running

```sh
# Profile recorded?
cat ~/.config/setup-profile         # should print: server

# Zsh starts fast?
time zsh -ic exit                   # < 200ms

# fail2ban running?
sudo fail2ban-client status sshd

# unattended-upgrades on?
sudo systemctl is-active unattended-upgrades

# Pi-hole cron?
cat /etc/cron.d/pihole-backup

# tmux config picked up?
tmux new-session -d -s test 'tmux show -g | head -20' && tmux kill-session -t test
```

## Adding a new SBC later

```sh
git clone https://github.com/r0mankon/dotfiles ~/.dotfiles
./~/.dotfiles/setup.linux-server.sh
```

That's it. Idempotent — re-runs are safe (state tracked in `~/.dotfiles-setup-state`).
