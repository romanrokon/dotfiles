#!/bin/bash
# Called by aria2 on download complete/error.
# Args: $1 = GID, $2 = numFiles, $3 = filepath (first file)

GID="$1"
NUM_FILES="$2"
FILEPATH="$3"
FILENAME=$(basename "$FILEPATH")

[ -z "$FILENAME" ] && exit 0

if [ -f "$FILEPATH" ] && [ -s "$FILEPATH" ]; then
  SIZE=$(du -h "$FILEPATH" 2>/dev/null | cut -f1)
  TITLE="✅ Download complete"
  MSG="$FILENAME ($SIZE)"
  URGENCY="normal"
else
  TITLE="❌ Download failed"
  MSG="$FILENAME"
  URGENCY="critical"
fi

case "$(uname)" in
  Darwin)
    osascript -e "display notification \"$MSG\" with title \"$TITLE\" sound name \"Glass\""
    ;;
  Linux)
    notify-send -u "$URGENCY" "$TITLE" "$MSG"
    ;;
esac
