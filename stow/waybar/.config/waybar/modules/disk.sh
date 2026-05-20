#!/bin/bash
# Waybar custom module: disk usage across volumes.
# Highest pct wins in display.

VOLUMES=("/" "/home" "/mnt/work")  # adjust to your Linux mount layout
WARN_PCT=80
CRIT_PCT=90

MAX_PCT=0
MAX_PATH=""
DETAILS=""

for v in "${VOLUMES[@]}"; do
  [ ! -d "$v" ] && continue
  PCT=$(df --output=pcent "$v" 2>/dev/null | tail -1 | tr -d ' %')
  USED=$(df -h --output=used "$v" 2>/dev/null | tail -1 | tr -d ' ')
  AVAIL=$(df -h --output=avail "$v" 2>/dev/null | tail -1 | tr -d ' ')
  TOTAL=$(df -h --output=size "$v" 2>/dev/null | tail -1 | tr -d ' ')
  [ -z "$PCT" ] && continue
  DETAILS+="${v} ${PCT}% (${USED}/${TOTAL}, ${AVAIL} free)\n"
  if [ "$PCT" -gt "$MAX_PCT" ]; then
    MAX_PCT=$PCT
    MAX_PATH=$v
  fi
done

CLASS="ok"
[ "$MAX_PCT" -ge "$WARN_PCT" ] && CLASS="warn"
[ "$MAX_PCT" -ge "$CRIT_PCT" ] && CLASS="error"

# strip trailing \n for tooltip
TOOLTIP=$(printf "%b" "$DETAILS" | sed 's/$//')
printf '{"text":"󰋊 %d%%","tooltip":"%s","class":"%s"}\n' "$MAX_PCT" "${TOOLTIP//$'\n'/\\n}" "$CLASS"
