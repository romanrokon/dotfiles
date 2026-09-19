#!/bin/bash
# @ AI Context: Installs the free AltTab fork (vemonet/alt-tab-macos-free) from
# the vendored release zip. Upstream lwouis/alt-tab-macos moved icon-only mode
# behind Pro and pulled old free builds, so the brew `alt-tab` cask must not be
# used. The zip is vendored because the fork could disappear too.
#
# The release zip nests a second zip (AltTab-local-pro.zip) holding the .app;
# Archive Utility fails on it, so extract both layers with ditto.
#
# The app is self-signed (no Team ID). Consequences:
# - quarantine must be stripped or Gatekeeper blocks launch.
# - macOS TCC grants are tied to the signature. Old grants from the upstream
#   build (same bundle id) silently fail, so reset them on install.
# - Sparkle updater still points at upstream; auto-checks are disabled so it
#   never offers the paywalled upstream build.
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
ZIP="$DIR/AltTab-pro-v11.4.3.zip"
SHA256="3b13538e23f0b056a39c5312f6ca46b3184bbb2989636ca6fc390e113ff537df"
BUNDLE_ID="com.lwouis.alt-tab-macos"
DEST="/Applications/AltTab.app"

if [ "${DRY_RUN:-0}" = "1" ]; then
    echo "[DRY] alttab: would install $DEST from $ZIP"
    exit 0
fi

if [ "$(uname -s)" != "Darwin" ]; then
    echo "alttab: macOS only, skipping"
    exit 0
fi

if [ "$(uname -m)" != "arm64" ]; then
    echo "alttab: vendored build is arm64 only, skipping" >&2
    exit 1
fi

actual="$(shasum -a 256 "$ZIP" | awk '{print $1}')"

if [ "$actual" != "$SHA256" ]; then
    echo "alttab: checksum mismatch for $ZIP" >&2
    exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

ditto -x -k "$ZIP" "$tmp"
ditto -x -k "$tmp/AltTab-local-pro.zip" "$tmp/app"

pkill -x AltTab 2>/dev/null || true

if [ -d "$DEST" ]; then
    trash "$DEST" 2>/dev/null || rm -rf "$DEST"
fi

ditto "$tmp/app/AltTab.app" "$DEST"
xattr -dr com.apple.quarantine "$DEST" 2>/dev/null || true

defaults write "$BUNDLE_ID" SUEnableAutomaticChecks -bool false
defaults write "$BUNDLE_ID" SUAutomaticallyUpdate -bool false
defaults write "$BUNDLE_ID" updatePolicy -int 0

tccutil reset Accessibility "$BUNDLE_ID" >/dev/null 2>&1 || true
tccutil reset ScreenCapture "$BUNDLE_ID" >/dev/null 2>&1 || true

open "$DEST"
echo "alttab: installed v11.4.3. Grant Accessibility (and Screen Recording for thumbnails) in System Settings."
