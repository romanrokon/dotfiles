#!/bin/bash
# @ AI Context: Thin shim — runs the main wizard with SETUP_PROFILE=server,
# producing a minimal CLI environment for headless Linux SBCs (Pi, OrangePi).
# Skips GUI packages, language runtimes, Mac-only stow packages, and adds
# fail2ban + unattended-upgrades + interactive SSH hardening.

export SETUP_PROFILE=server
exec "$(dirname "$0")/setup.sh" "$@"
