#!/bin/bash
# @ AI Context: Block until any background jobs started earlier (apps install)
# finish. Without this, the wizard could exit while brew is still downloading.

step_wait_bg() {
    tui_msg "Background tasks" "Waiting for background apps install to finish. Progress in $LOG_FILE."
    bg_wait_all
}
