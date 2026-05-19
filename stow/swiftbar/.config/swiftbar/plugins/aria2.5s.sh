#!/bin/bash
# SwiftBar plugin: aria2 daemon status + controls.
# Filename suffix .5s.sh => refresh every 5 seconds.
#
# <swiftbar.title>aria2</swiftbar.title>
# <swiftbar.author>rzman</swiftbar.author>
# <swiftbar.desc>Status + control for aria2 daemon</swiftbar.desc>
# <swiftbar.dependencies>aria2,curl,jq</swiftbar.dependencies>
# <swiftbar.refreshOnOpen>true</swiftbar.refreshOnOpen>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

RPC_URL="http://localhost:6800/jsonrpc"
RPC_SECRET="changeme-local-only"
PLIST="$HOME/Library/LaunchAgents/com.rzman.aria2.plist"
LABEL="com.rzman.aria2"
# Hosted AriaNg with RPC preset baked into URL (secret base64-encoded)
ARIANG_URL="https://ariang.mayswind.net/latest/#!/settings/rpc/set?protocol=http&host=localhost&port=6800&interface=jsonrpc&secret=Y2hhbmdlbWUtbG9jYWwtb25seQ%3D%3D"

rpc() {
  local method=$1
  shift
  local params="\"token:$RPC_SECRET\""
  [ $# -gt 0 ] && params="$params,$*"
  curl -s -m 2 -X POST "$RPC_URL" \
    -d "{\"jsonrpc\":\"2.0\",\"id\":\"sb\",\"method\":\"$method\",\"params\":[$params]}"
}

# --- check running ---
RUNNING=0
GLOBAL_STAT=$(rpc aria2.getGlobalStat 2>/dev/null)
if [ -n "$GLOBAL_STAT" ] && echo "$GLOBAL_STAT" | grep -q '"result"'; then
  RUNNING=1
fi

# Format bytes/sec → human readable (KB/MB/GB)
fmt_speed() {
  awk -v b="$1" 'BEGIN{
    if (b >= 1073741824) printf "%.2f GB/s", b/1073741824
    else if (b >= 1048576) printf "%.2f MB/s", b/1048576
    else if (b >= 1024) printf "%.1f KB/s", b/1024
    else printf "%d B/s", b
  }'
}

# Format bytes → human readable (KB/MB/GB)
fmt_bytes() {
  awk -v b="$1" 'BEGIN{
    if (b >= 1073741824) printf "%.2f GB", b/1073741824
    else if (b >= 1048576) printf "%.2f MB", b/1048576
    else if (b >= 1024) printf "%.1f KB", b/1024
    else printf "%d B", b
  }'
}

# --- menu bar text ---
if [ "$RUNNING" = 1 ]; then
  ACTIVE=$(echo "$GLOBAL_STAT" | jq -r '.result.numActive // "0"')
  WAITING=$(echo "$GLOBAL_STAT" | jq -r '.result.numWaiting // "0"')
  DL_SPEED=$(echo "$GLOBAL_STAT" | jq -r '.result.downloadSpeed // "0"')
  if [ "$ACTIVE" -gt 0 ]; then
    echo "⬇ $ACTIVE • $(fmt_speed $DL_SPEED)"
  else
    echo "⬇ idle"
  fi
else
  echo "⬇ off | color=gray"
fi

echo "---"

if [ "$RUNNING" = 1 ]; then
  echo "✓ aria2 running"
  echo "Active: $ACTIVE   Waiting: $WAITING"
  echo "↓ $(fmt_speed $DL_SPEED)"
  echo "---"

  # Active downloads list with progress
  ACTIVE_JSON=$(rpc aria2.tellActive)
  if [ -n "$ACTIVE_JSON" ]; then
    echo "$ACTIVE_JSON" | jq -r '.result[]? |
      "\(.files[0].path // "?" | split("/") | .[-1] | .[0:50])  \((.completedLength|tonumber)/((.totalLength|tonumber)+0.0001)*100 | floor)%  \(.completedLength)/\(.totalLength) | size=11 trim=true"' 2>/dev/null | \
    while IFS= read -r line; do
      # Replace raw byte counts with human-readable
      done_b=$(echo "$line" | awk -F'  ' '{print $3}' | awk -F'/' '{print $1}')
      total_b=$(echo "$line" | awk -F'  ' '{print $3}' | awk -F'/' '{split($2,a," "); print a[1]}')
      meta=$(echo "$line" | awk -F'  ' '{print $3}' | awk -F'/' '{split($2,a," "); for(i=2;i<=length(a);i++) printf " %s",a[i]}')
      name_pct=$(echo "$line" | awk -F'  ' '{print $1"  "$2}')
      done_h=$(fmt_bytes $done_b)
      total_h=$(fmt_bytes $total_b)
      echo "$name_pct  $done_h / $total_h |$meta"
    done | head -10
  fi
  echo "---"
else
  echo "✗ aria2 not running | color=red"
  echo "---"
fi

# Actions
echo "Open web UI (AriaNg) | href=$ARIANG_URL"
echo "Open Downloads folder | bash=open param0=$HOME/Downloads terminal=false"
echo "---"

if [ "$RUNNING" = 1 ]; then
  echo "Pause all | bash=curl param0=-s param1=-X param2=POST param3=$RPC_URL param4=-d param5='{\"jsonrpc\":\"2.0\",\"id\":\"p\",\"method\":\"aria2.pauseAll\",\"params\":[\"token:$RPC_SECRET\"]}' terminal=false refresh=true"
  echo "Resume all | bash=curl param0=-s param1=-X param2=POST param3=$RPC_URL param4=-d param5='{\"jsonrpc\":\"2.0\",\"id\":\"r\",\"method\":\"aria2.unpauseAll\",\"params\":[\"token:$RPC_SECRET\"]}' terminal=false refresh=true"
  echo "Stop daemon | bash=launchctl param0=bootout param1=gui/$(id -u)/$LABEL terminal=false refresh=true"
else
  echo "Start daemon | bash=launchctl param0=bootstrap param1=gui/$(id -u) param2=$PLIST terminal=false refresh=true"
fi

# Auto-start toggle
DISABLED_STATE=$(launchctl print-disabled gui/$(id -u) 2>/dev/null | grep "\"$LABEL\"" | grep -c "true")
if [ "$DISABLED_STATE" = "1" ]; then
  echo "Enable auto-start | bash=launchctl param0=enable param1=gui/$(id -u)/$LABEL terminal=false refresh=true"
else
  echo "Disable auto-start | bash=launchctl param0=disable param1=gui/$(id -u)/$LABEL terminal=false refresh=true"
fi

echo "---"
echo "View log | bash=open param0=-a param1=Console param2=$HOME/.aria2/aria2.log terminal=false"
echo "Edit config | bash=open param0=-t param1=$HOME/.aria2/aria2.conf terminal=false"
echo "Refresh | refresh=true"
