#!/bin/bash
# @ AI Context: Final summary screen. Shows completed steps and next actions.

step_summary() {
    local done_steps
    done_steps=$(cat "$STATE_FILE" 2>/dev/null | sed 's/^/  - /')
    local body
    body="Setup complete on $OS_NAME.

Completed steps:
$done_steps

Logs: $LOG_FILE
State: $STATE_FILE

Next:
  - Restart terminal (or 'exec zsh') for shell changes to take effect.
  - Verify private dotfiles in ~/.dotfiles-private.
  - Check 'gh auth status' if you skipped the auth step."
    tui_msg "All done" "$body"
}
