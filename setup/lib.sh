#!/bin/bash
# @ AI Context: Shared library for the setup wizard. Provides OS detection,
# state tracking (~/.dotfiles-setup-state), TUI helpers around whiptail,
# and a run_step harness that handles retry/skip/abort on failure.

set -uo pipefail

# @ AI Context: Dry-run mode. When DRY_RUN=1, destructive commands are shimmed
# to log what they WOULD do instead of executing. Read-only commands
# (command -v, grep, test, [ ], stat) run normally so detection logic still
# works and the wizard reflects realistic skip/install decisions.
DRY_RUN="${DRY_RUN:-0}"

_dry_log() {
    local msg="[DRY] $*"
    echo "$msg" >&2
    echo "$msg" >> "${LOG_FILE:-/dev/null}"
}

# @ AI Context: Shim destructive commands when DRY_RUN=1. Bash resolves
# functions before $PATH, so these intercept calls in every step file
# without requiring per-step wrappers.
_install_dry_shims() {
    [ "$DRY_RUN" = "1" ] || return 0
    # @ AI Context: export -f so shims propagate to subshells. For separate
    # script invocations (./stow-all.sh, ./setup.private.sh), the scripts
    # themselves also check $DRY_RUN at the top and exit early — function
    # exports alone do NOT cross a `bash other-script.sh` boundary, so the
    # in-script guards are the real protection there. Exports help for any
    # subshell-level work inside this wizard.
    for cmd in brew apt apt-get sudo chsh defaults gh stow killall \
               add-apt-repository systemctl xargs tee chmod; do
        eval "$cmd() { _dry_log \"$cmd \$*\"; return 0; }"
        export -f "$cmd"
    done
    git() {
        case "${1:-}" in
            status|log|rev-parse|diff|show|branch|remote|config) command git "$@" ;;
            *) _dry_log "git $*"; return 0 ;;
        esac
    }
    sed() {
        for a in "$@"; do [ "$a" = "-i" ] && { _dry_log "sed $*"; return 0; }; done
        command sed "$@"
    }
    bash() {
        if [ "${1:-}" = "-c" ] && [[ "${2:-}" == *"install.sh"* || "${2:-}" == *"curl"* ]]; then
            _dry_log "bash $*"
            return 0
        fi
        command bash "$@"
    }
    export -f git sed bash _dry_log
    export DRY_RUN LOG_FILE
}

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/.dotfiles}"
STATE_FILE="${STATE_FILE:-$HOME/.dotfiles-setup-state}"
LOG_FILE="${LOG_FILE:-$HOME/.dotfiles-setup.log}"
BG_PID_FILE="${BG_PID_FILE:-$HOME/.dotfiles-setup.bgpid}"

# @ AI Context: OS detection. Sets OS_NAME to "mac" or "linux".
detect_os() {
    case "$(uname -s)" in
        Darwin) OS_NAME="mac" ;;
        Linux)  OS_NAME="linux" ;;
        *) echo "Unsupported OS: $(uname -s)"; exit 1 ;;
    esac
    export OS_NAME
}

# @ AI Context: State helpers. State file is plain text, one step slug per line.
state_done() {
    [ -f "$STATE_FILE" ] && grep -Fxq "$1" "$STATE_FILE"
}

state_mark() {
    mkdir -p "$(dirname "$STATE_FILE")"
    touch "$STATE_FILE"
    state_done "$1" || echo "$1" >> "$STATE_FILE"
}

state_unmark() {
    [ -f "$STATE_FILE" ] || return 0
    grep -Fxv "$1" "$STATE_FILE" > "$STATE_FILE.tmp" || true
    mv "$STATE_FILE.tmp" "$STATE_FILE"
}

# @ AI Context: Logging. Everything funneled to $LOG_FILE plus stderr for errors.
log_init() {
    mkdir -p "$(dirname "$LOG_FILE")"
    : > "$LOG_FILE"
}

log_info() { echo "[INFO  $(date +%H:%M:%S)] $*" >> "$LOG_FILE"; }
log_err()  { echo "[ERROR $(date +%H:%M:%S)] $*" | tee -a "$LOG_FILE" >&2; }

# @ AI Context: TUI helpers around whiptail. Fall back to plain prompts if
# whiptail not yet installed (only true during very first prereq step).
tui_available() { command -v whiptail >/dev/null 2>&1; }

tui_msg() {
    local title="$1" body="$2"
    if tui_available; then
        whiptail --title "$title" --msgbox "$body" 15 70
    else
        echo "=== $title ==="
        echo "$body"
        read -r -p "Press enter to continue..." _
    fi
}

tui_yesno() {
    local title="$1" body="$2"
    if tui_available; then
        whiptail --title "$title" --yesno "$body" 15 70
    else
        local ans
        read -r -p "$title: $body [y/N] " ans
        [[ "$ans" =~ ^[Yy]$ ]]
    fi
}

# Returns chosen tag on stdout. Args: title, body, then tag1 desc1 tag2 desc2...
tui_menu() {
    local title="$1"; shift
    local body="$1"; shift
    if tui_available; then
        whiptail --title "$title" --menu "$body" 20 70 10 "$@" 3>&1 1>&2 2>&3
    else
        echo "=== $title ===" >&2
        echo "$body" >&2
        local i=1 tags=() ; while [ $# -gt 0 ]; do
            tags+=("$1")
            echo "  $i) $1 - $2" >&2
            shift 2; i=$((i+1))
        done
        local sel
        read -r -p "Pick number: " sel
        echo "${tags[$((sel-1))]}"
    fi
}

# @ AI Context: run_step harness. Skip if state file says done (unless forced).
# On failure prompts retry/skip/abort.
# Args: step_slug, human_name, function_to_call
run_step() {
    local slug="$1" name="$2" fn="$3"

    if state_done "$slug"; then
        if [ "${FORCE_RERUN:-0}" = "1" ]; then
            log_info "Re-running completed step: $slug"
        else
            log_info "Skipping completed step: $slug"
            return 0
        fi
    fi

    while true; do
        log_info "Step start: $slug ($name)"
        if "$fn"; then
            state_mark "$slug"
            log_info "Step done: $slug"
            return 0
        fi

        log_err "Step failed: $slug"
        local choice
        choice=$(tui_menu "Step failed: $name" \
            "Step '$name' failed. See $LOG_FILE for details. What now?" \
            retry "Retry this step" \
            skip  "Skip and continue (mark done)" \
            abort "Abort wizard")
        case "$choice" in
            retry) continue ;;
            skip)  state_mark "$slug"; return 0 ;;
            abort) exit 1 ;;
        esac
    done
}

# @ AI Context: Background job tracking. Used by apps-install step so gh-auth
# step can run while apps download. wait_bg blocks until BG completes.
bg_start() {
    local slug="$1"; shift
    log_info "BG start: $slug"
    ( "$@" ) >> "$LOG_FILE" 2>&1 &
    echo "$!:$slug" >> "$BG_PID_FILE"
}

bg_wait_all() {
    [ -f "$BG_PID_FILE" ] || return 0
    local entry pid slug
    while read -r entry; do
        pid="${entry%%:*}"
        slug="${entry##*:}"
        if kill -0 "$pid" 2>/dev/null; then
            log_info "Waiting on BG: $slug ($pid)"
            local dots=""
            while kill -0 "$pid" 2>/dev/null; do
                sleep 2
                dots+="."
                printf "\rWaiting on %s%s   " "$slug" "$dots" >&2
            done
            printf "\n" >&2
        fi
        wait "$pid" 2>/dev/null || log_err "BG step $slug exited non-zero"
    done < "$BG_PID_FILE"
    rm -f "$BG_PID_FILE"
}
