#!/bin/bash
# SwiftBar plugin: disk space monitor for multiple volumes + cleanup actions.
# Refresh every 1 minute.
#
# <swiftbar.title>Disk</swiftbar.title>
# <swiftbar.desc>Disk space for /, /Volumes/Data, /Volumes/Work</swiftbar.desc>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

WARN_PCT=80
CRIT_PCT=90

VOLUMES=(
  "/"
  "/Volumes/Work"
)

# Returns: used_pct used_h total_h free_h color
volume_stat() {
  local mount=$1
  if [ ! -d "$mount" ]; then
    echo "missing"
    return
  fi
  # df -k output: filesystem 1024-blocks used avail capacity ...
  local line
  line=$(df -k "$mount" 2>/dev/null | tail -1)
  [ -z "$line" ] && { echo "missing"; return; }
  local total_k used_k free_k pct
  total_k=$(echo "$line" | awk '{print $2}')
  used_k=$(echo "$line" | awk '{print $3}')
  free_k=$(echo "$line" | awk '{print $4}')
  pct=$(echo "$line" | awk '{print $5}' | tr -d '%')

  local fmt_used fmt_total fmt_free
  fmt_used=$(awk -v k="$used_k" 'BEGIN{
    if (k>=1048576) printf "%.1fG", k/1048576
    else if (k>=1024) printf "%.0fM", k/1024
    else printf "%dK", k}')
  fmt_total=$(awk -v k="$total_k" 'BEGIN{
    if (k>=1048576) printf "%.0fG", k/1048576
    else printf "%.0fM", k/1024}')
  fmt_free=$(awk -v k="$free_k" 'BEGIN{
    if (k>=1048576) printf "%.1fG", k/1048576
    else printf "%.0fM", k/1024}')

  local color="white"
  [ "$pct" -ge "$WARN_PCT" ] && color="orange"
  [ "$pct" -ge "$CRIT_PCT" ] && color="red"

  echo "$pct $fmt_used $fmt_total $fmt_free $color"
}

# --- menubar: highest pct across volumes ---
MAX_PCT=0
MAX_COLOR="white"
for v in "${VOLUMES[@]}"; do
  read -r pct _ _ _ color <<<"$(volume_stat "$v")"
  [ "$pct" = "missing" ] && continue
  if [ "$pct" -gt "$MAX_PCT" ]; then
    MAX_PCT=$pct
    MAX_COLOR=$color
  fi
done

if [ "$MAX_COLOR" = "white" ]; then
  echo "💽 ${MAX_PCT}%"
else
  echo "💽 ${MAX_PCT}% | color=$MAX_COLOR"
fi

echo "---"

# --- per-volume details ---
for v in "${VOLUMES[@]}"; do
  stat=$(volume_stat "$v")
  if [ "$stat" = "missing" ]; then
    echo "✗ $v not mounted | color=gray"
    echo "---"
    continue
  fi
  read -r pct used total free color <<<"$stat"

  vol_name=$(basename "$v")
  [ "$v" = "/" ] && vol_name="System"

  echo "💾 $vol_name  ${pct}%  ${used}/${total}  (${free} free) | color=$color"

  # Submenu items
  echo "-- Open in Finder | bash=open param0=$v terminal=false"
  TRASH="$v/.Trashes/$(id -u)"
  [ "$v" = "/" ] && TRASH="$HOME/.Trash"
  if [ -d "$TRASH" ]; then
    TRASH_SIZE=$(du -sh "$TRASH" 2>/dev/null | cut -f1)
    echo "-- Empty trash on $vol_name (${TRASH_SIZE:-?}) | bash=/bin/rm param0=-rf param1=$TRASH/* terminal=false refresh=true"
  fi
  echo "-- Top 10 biggest dirs (terminal) | bash=$HOME/.bin/in-ghostty param0=/bin/sh param1=-c param2='du -sh $v/* 2>/dev/null | sort -rh | head -20'"
  echo "---"
done

# --- global cleanup actions ---
echo "🧹 Cleanup actions"
echo "-- Brew cleanup (frees brew caches) | bash=$HOME/.bin/in-ghostty param0=/opt/homebrew/bin/brew param1=cleanup refresh=true"
echo "-- Docker/OrbStack prune | bash=$HOME/.bin/in-ghostty param0=/usr/local/bin/docker param1=system param2=prune param3=-af refresh=true"
echo "-- Empty all trashes | bash=/usr/bin/osascript param0=-e param1='tell application \"Finder\" to empty trash' terminal=false refresh=true"
echo "-- Purge inactive RAM | bash=$HOME/.bin/in-ghostty param0=/usr/bin/sudo param1=purge"
echo "-- Clear ~/Library/Caches (heavy) | bash=$HOME/.bin/in-ghostty param0=/bin/sh param1=-c param2='du -sh ~/Library/Caches; read -p \"Delete? (y/n): \" a; [ \"\$a\" = y ] && rm -rf ~/Library/Caches/*' refresh=true"
echo "---"

echo "Refresh | refresh=true"
