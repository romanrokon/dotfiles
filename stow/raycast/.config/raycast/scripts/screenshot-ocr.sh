#!/usr/bin/env bash
# @raycast.schemaVersion 1
# @raycast.title Screenshot OCR
# @raycast.mode silent
# @raycast.icon 📸
# @raycast.packageName Screenshots
# @raycast.description OCR the latest ~/Screenshots screenshot. Image stays as the active clipboard item; OCR text is pushed first so Raycast history keeps it as the previous entry.

set -u

shot=$(find "$HOME/Screenshots" -maxdepth 1 -type f \
    \( -name 'Screenshot *.png' -o -name 'Screen Shot *.png' \) \
    -print0 2>/dev/null \
    | xargs -0 stat -f '%m %N' 2>/dev/null \
    | sort -rn | head -1 | cut -d' ' -f2-)

[ -z "$shot" ] && { echo "no screenshot in ~/Screenshots"; exit 1; }
[ -f "$shot" ] || { echo "no screenshot in ~/Screenshots"; exit 1; }

text=$("$HOME/.bin/macocr" "$shot" 2>/dev/null || true)

if [ -n "$text" ]; then
    printf '%s' "$text" | pbcopy
fi

osascript -e "set the clipboard to (read (POSIX file \"$shot\") as «class PNGf»)"

echo "OCR done: $(basename "$shot")"
