#!/bin/bash
# @ AI Context: Entry point for the interactive dotfiles setup wizard.
# Detects OS, sources lib + step files in order, and runs each step through
# the run_step harness (which handles state tracking + retry/skip/abort).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR="$SCRIPT_DIR"

# shellcheck source=setup/lib.sh
source "$SCRIPT_DIR/setup/lib.sh"

detect_os
log_init
log_info "Wizard started on $OS_NAME"

# @ AI Context: Flag parsing. Supports --reset, --force, --dry-run (combinable).
for arg in "$@"; do
    case "$arg" in
        --reset)   rm -f "$STATE_FILE" "$BG_PID_FILE"; echo "State reset." ;;
        --force)   export FORCE_RERUN=1 ;;
        --dry-run) export DRY_RUN=1 ;;
        --help|-h)
            cat <<EOF
Usage: setup.sh [--reset] [--force] [--dry-run]
  --reset    Wipe state file ($STATE_FILE) and start fresh.
  --force    Re-run steps already marked done in state file.
  --dry-run  Shim destructive commands; show what WOULD run, change nothing.
             Forces --force so all steps execute (logged, not applied).
             Uses a temp state file so real state is not touched.
EOF
            exit 0
            ;;
    esac
done

if [ "${DRY_RUN:-0}" = "1" ]; then
    export FORCE_RERUN=1
    # Isolate state + log so dry-run doesn't poison real runs
    export STATE_FILE="$HOME/.dotfiles-setup-state.dry"
    export LOG_FILE="$HOME/.dotfiles-setup.dry.log"
    export BG_PID_FILE="$HOME/.dotfiles-setup.bgpid.dry"
    rm -f "$STATE_FILE" "$BG_PID_FILE"
    echo "DRY RUN mode. Nothing will be modified. State -> $STATE_FILE, log -> $LOG_FILE"
fi

# @ AI Context: Always clear stale BG PID file at start. Without this, a
# wizard run aborted mid-flight could leave PIDs in $BG_PID_FILE that get
# reused by unrelated processes, causing wait_bg to block on the wrong PID.
rm -f "$BG_PID_FILE"

_install_dry_shims

# @ AI Context: Step list. Order matters. Each entry: "slug|name|file".
STEPS=(
    "welcome|Welcome|00-welcome.sh"
    "prereqs|Install prerequisites (brew/apt, git, gh, zsh, stow, whiptail)|01-prereqs.sh"
    "zsh_dotfiles|Stow public dotfiles + set zsh as shell|02-zsh-dotfiles.sh"
    "apps_bg|Kick off apps install in background|03-apps-bg.sh"
    "gh_auth|Authenticate with GitHub (gh auth login)|04-gh-auth.sh"
    "private_repo|Clone + stow private dotfiles repo|05-private-repo.sh"
    "os_tweaks|Apply OS tweaks (defaults / sysctl)|06-os-tweaks.sh"
    "server_harden|Server hardening (fail2ban + SSH + cron) [server profile only]|06b-server-hardening.sh"
    "runtimes|Install NVM + Cargo apps|07-runtimes.sh"
    "wait_bg|Wait for background apps install to finish|08-wait-bg.sh"
    "summary|Final summary|09-summary.sh"
)

for entry in "${STEPS[@]}"; do
    IFS='|' read -r slug name file <<<"$entry"
    # shellcheck source=/dev/null
    source "$SCRIPT_DIR/setup/steps/$file"
    # Convention: each step file defines a function named step_<slug>
    run_step "$slug" "$name" "step_$slug"
done

log_info "Wizard finished."
