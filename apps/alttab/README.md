# AltTab (free fork)

Vendored build of [vemonet/alt-tab-macos-free v11.4.3](https://github.com/vemonet/alt-tab-macos-free/releases/tag/v11.4.3), a fork of `lwouis/alt-tab-macos` with Pro features unlocked. Upstream moved icon-only mode behind Pro and removed old free builds, so the brew `alt-tab` cask is not used.

- `AltTab-pro-v11.4.3.zip`: release asset exactly as downloaded, arm64, self-signed.
- sha256: `3b13538e23f0b056a39c5312f6ca46b3184bbb2989636ca6fc390e113ff537df`

## Install

```sh
./apps/alttab/install.sh
```

`setup.sh` runs this on macOS after the brew install. The script checks the checksum, extracts the nested zip, installs to `/Applications`, removes quarantine, disables Sparkle update checks and resets old permission grants.

Then enable AltTab in System Settings › Privacy & Security › Accessibility (and Screen Recording for thumbnails). If the toggle does nothing, remove the entry with − and add `/Applications/AltTab.app` again.

## Updating

Never use AltTab's "Check for updates". It points at upstream. To update, replace the zip with a newer fork release, then update the file name and `SHA256` in `install.sh`.
