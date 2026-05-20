#!/bin/bash
# Waybar custom module: aria2 daemon status.
# Outputs JSON {text, tooltip, class}.
# Usage in waybar config:
#   "custom/aria2": {
#     "exec": "~/.config/waybar/modules/aria2.sh",
#     "return-type": "json",
#     "interval": 5,
#     "on-click": "xdg-open https://ariang.mayswind.net/latest/"
#   }

RPC_URL="http://localhost:6800/jsonrpc"
SECRET="changeme-local-only"

fmt_speed() {
  awk -v b="$1" 'BEGIN{
    if (b >= 1073741824) printf "%.1f GB/s", b/1073741824
    else if (b >= 1048576) printf "%.1f MB/s", b/1048576
    else if (b >= 1024) printf "%.0f KB/s", b/1024
    else printf "%d B/s", b
  }'
}

RESP=$(curl -s -m 2 -X POST "$RPC_URL" -d "{\"jsonrpc\":\"2.0\",\"id\":\"w\",\"method\":\"aria2.getGlobalStat\",\"params\":[\"token:$SECRET\"]}" 2>/dev/null)

if [ -z "$RESP" ] || ! echo "$RESP" | grep -q '"result"'; then
  echo '{"text":"󰇚 off","tooltip":"aria2 daemon not reachable","class":"off"}'
  exit 0
fi

ACTIVE=$(echo "$RESP" | jq -r '.result.numActive // "0"')
WAITING=$(echo "$RESP" | jq -r '.result.numWaiting // "0"')
SPEED=$(echo "$RESP" | jq -r '.result.downloadSpeed // "0"')
SPEED_H=$(fmt_speed "$SPEED")

if [ "$ACTIVE" -gt 0 ]; then
  TEXT="󰇚 $ACTIVE • $SPEED_H"
  CLASS="active"
else
  TEXT="󰇚"
  CLASS="idle"
fi

TOOLTIP="aria2: active $ACTIVE • waiting $WAITING\nspeed: $SPEED_H"
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
