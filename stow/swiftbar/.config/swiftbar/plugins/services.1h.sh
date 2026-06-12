#!/usr/bin/env bash
# <bitbar.title>Services</bitbar.title>
# <bitbar.desc>Personal background services dashboard: screenshot iCloud sync, Claude slack bot, LaunchAgents, toggles.</bitbar.desc>

set -u
export PATH=/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin

UID_NUM=$(id -u)
STATE_DIR="$HOME/.cache"
mkdir -p "$STATE_DIR"

# ── Screenshots iCloud sync — run if state >7d old ────────────────────────────
SS_STATE="$STATE_DIR/screenshots-icloud-sync.last"
SS_LAST=0
[ -f "$SS_STATE" ] && SS_LAST=$(stat -f %m "$SS_STATE" 2>/dev/null || echo 0)
NOW=$(date +%s)
SS_AGE=$((NOW - SS_LAST))
WEEK=604800

if [ "$SS_AGE" -gt "$WEEK" ]; then
    if "$HOME/.bin/screenshots-icloud-sync" >/dev/null 2>&1; then
        date +%s > "$SS_STATE"
    fi
fi

if [ "$SS_LAST" = 0 ]; then
    SS_DISPLAY="never"
else
    SS_DISPLAY=$(date -r "$SS_LAST" '+%b %d %H:%M')
fi

# ── LaunchAgent state helper ──────────────────────────────────────────────────
agent_state() {
    local label=$1
    local line
    line=$(launchctl list 2>/dev/null | awk -v l="$label" '$3==l {print $1; exit}')
    if [ -z "$line" ]; then
        printf '✗ missing'
    elif [ "$line" = "-" ]; then
        printf '○ loaded'
    else
        printf '✓ pid=%s' "$line"
    fi
}

# ── Toggles state ─────────────────────────────────────────────────────────────
SETTINGS="$HOME/.claude/settings.json"
VOICE=off
AUTOCOMPACT=on
EFFORT=medium
if [ -f "$SETTINGS" ]; then
    VOICE=$(jq -r 'if .voiceEnabled then "on" else "off" end' "$SETTINGS" 2>/dev/null || echo off)
    AUTOCOMPACT=$(jq -r 'if .autoCompactEnabled then "on" else "off" end' "$SETTINGS" 2>/dev/null || echo on)
    EFFORT=$(jq -r '.effortLevel // "medium"' "$SETTINGS" 2>/dev/null || echo medium)
fi

# ── Menu output ───────────────────────────────────────────────────────────────
echo "⚙︎"
echo "---"

# Screenshots iCloud sync
echo "📸 Screenshots iCloud sync"
echo "-- Last: $SS_DISPLAY"
echo "-- Sync now | bash=$HOME/.bin/screenshots-icloud-sync-force terminal=false refresh=true"
echo "-- Open ~/Screenshots | bash=/usr/bin/open param0=$HOME/Screenshots terminal=false"
echo "-- Open iCloud Screenshots | bash=/usr/bin/open param0='$HOME/Library/Mobile Documents/com~apple~CloudDocs/Screenshots' terminal=false"
echo "---"

# Pi-hole backup
PH_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Backups/pihole"
PH_LAST_FILE=$(/bin/ls -1t "$PH_DIR"/pihole-*.zip 2>/dev/null | head -1)
if [ -n "$PH_LAST_FILE" ]; then
    PH_LAST_TS=$(stat -f %m "$PH_LAST_FILE" 2>/dev/null || echo 0)
    PH_DISPLAY=$(date -r "$PH_LAST_TS" '+%b %d %H:%M')
    PH_COUNT=$(/bin/ls -1 "$PH_DIR"/pihole-*.zip 2>/dev/null | wc -l | tr -d ' ')
else
    PH_DISPLAY="never"
    PH_COUNT=0
fi
echo "🛡 Pi-hole backup"
echo "-- Last: $PH_DISPLAY ($PH_COUNT kept)"
echo "-- Backup now | bash=$HOME/.bin/pihole-backup terminal=false refresh=true"
echo "-- Tail log | bash=$HOME/.bin/in-ghostty param0=tail param1=-f param2=$HOME/.aria2/pihole-backup.log"
echo "-- Open backup folder | bash=/usr/bin/open param0='$PH_DIR' terminal=false"
echo "---"

# Claude Slack bot
CSB=com.rzman.claude-slack-bot
echo "🤖 Claude Slack bot: $(agent_state "$CSB")"
echo "-- Tail logs | bash=$HOME/.bin/in-ghostty param0=tail param1=-f param2=$HOME/Library/Logs/claude-slack-bot.log"
echo "-- Restart | bash=/bin/launchctl param0=kickstart param1=-k param2=gui/$UID_NUM/$CSB terminal=false refresh=true"
echo "-- Stop   | bash=/bin/launchctl param0=bootout param1=gui/$UID_NUM/$CSB terminal=false refresh=true"
echo "-- Start  | bash=/bin/launchctl param0=bootstrap param1=gui/$UID_NUM param2=$HOME/Library/LaunchAgents/$CSB.plist terminal=false refresh=true"
echo "---"

# Quick toggles
echo "⚡ Toggles"
echo "-- Voice notifications: $VOICE | bash=$HOME/.bin/toggle-claude-setting param0=voiceEnabled terminal=false refresh=true"
echo "-- Auto-compact: $AUTOCOMPACT | bash=$HOME/.bin/toggle-claude-setting param0=autoCompactEnabled terminal=false refresh=true"
echo "-- Effort level: $EFFORT"
echo "---"

# LaunchAgents
echo "⚙ LaunchAgents"
for label in com.rzman.aria2 com.rzman.claude-slack-bot com.rzman.memwatch com.rzman.pihole-backup com.rzman.screenshot-to-clipboard com.rzman.screenshots-icloud-sync; do
    short=${label#com.rzman.}
    echo "-- $short: $(agent_state "$label")"
    echo "---- Restart | bash=/bin/launchctl param0=kickstart param1=-k param2=gui/$UID_NUM/$label terminal=false refresh=true"
done
echo "---"

echo "🔄 Refresh | refresh=true"
