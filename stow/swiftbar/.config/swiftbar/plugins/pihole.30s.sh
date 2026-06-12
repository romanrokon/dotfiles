#!/bin/bash
# SwiftBar plugin: Pi-hole over Tailscale status.
# Refresh every 30s.
#
# <swiftbar.title>Pi-hole</swiftbar.title>
# <swiftbar.desc>DNS + HTTP liveness probe for orangepi-pihole over Tailscale</swiftbar.desc>
# <swiftbar.dependencies>dig,curl,tailscale</swiftbar.dependencies>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:$PATH"

# Defaults; override via ~/.config/dotfiles/pihole.env (kept in private repo).
PIHOLE_HOST=""
PIHOLE_IP=""
PROBE_DOMAIN="google.com"
TIMEOUT=2

PIHOLE_ENV="$HOME/.config/dotfiles/pihole.env"
[ -f "$PIHOLE_ENV" ] && . "$PIHOLE_ENV"

if [ -z "$PIHOLE_IP" ]; then
  echo "🛡 ? | color=gray"
  echo "---"
  echo "Pi-hole not configured"
  echo "Create $PIHOLE_ENV with: | size=10 color=gray"
  echo "  PIHOLE_IP=100.x.x.x | size=10 color=gray"
  echo "  PIHOLE_HOST=name.tailnet.ts.net | size=10 color=gray"
  exit 0
fi

ADMIN_URL="http://${PIHOLE_IP}/admin"

# --- Tailscale up? ---
TS_STATUS=$(/Applications/Tailscale.app/Contents/MacOS/Tailscale status --json 2>/dev/null)
TS_UP=0
if [ -n "$TS_STATUS" ] && echo "$TS_STATUS" | grep -Eq '"BackendState":\s*"Running"'; then
  TS_UP=1
fi

# --- DNS probe ---
DNS_OK=0
DNS_MS=""
if [ "$TS_UP" = 1 ]; then
  START=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time()*1000')
  ANSWER=$(dig +short +time=$TIMEOUT +tries=1 @"$PIHOLE_IP" "$PROBE_DOMAIN" 2>/dev/null | head -1)
  END=$(perl -MTime::HiRes=time -e 'printf "%.0f\n", time()*1000')
  if [ -n "$ANSWER" ] && [[ "$ANSWER" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    DNS_OK=1
    DNS_MS=$((END - START))
  fi
fi

# --- HTTP admin probe ---
HTTP_OK=0
HTTP_CODE=""
if [ "$TS_UP" = 1 ]; then
  HTTP_CODE=$(curl -s -o /dev/null -m $TIMEOUT -w "%{http_code}" "$ADMIN_URL" 2>/dev/null)
  if [[ "$HTTP_CODE" =~ ^(200|301|302|307|308)$ ]]; then
    HTTP_OK=1
  fi
fi

# --- Menu bar ---
if [ "$TS_UP" = 0 ]; then
  echo "🛡 TS off | color=gray"
elif [ "$DNS_OK" = 1 ] && [ "$HTTP_OK" = 1 ]; then
  echo "🛡 ${DNS_MS}ms"
elif [ "$DNS_OK" = 1 ]; then
  echo "🛡 DNS only | color=orange"
elif [ "$HTTP_OK" = 1 ]; then
  echo "🛡 HTTP only | color=orange"
else
  echo "🛡 ✗ | color=red"
fi

echo "---"
echo "Pi-hole @ $PIHOLE_HOST"
echo "($PIHOLE_IP) | size=10 color=gray"
echo "---"

if [ "$TS_UP" = 0 ]; then
  echo "✗ Tailscale not running | color=red"
else
  echo "✓ Tailscale up"
fi

if [ "$DNS_OK" = 1 ]; then
  echo "✓ DNS resolves ${PROBE_DOMAIN} → ${ANSWER} (${DNS_MS}ms)"
else
  echo "✗ DNS probe failed | color=red"
fi

if [ "$HTTP_OK" = 1 ]; then
  echo "✓ Admin reachable (HTTP $HTTP_CODE)"
else
  echo "✗ Admin unreachable (HTTP ${HTTP_CODE:-none}) | color=red"
fi

echo "---"
echo "Open admin in browser | href=$ADMIN_URL"
echo "Ping pihole | bash=$HOME/.bin/in-ghostty param0=ping param1=-c param2=4 param3=$PIHOLE_IP"
echo "SSH to pihole | bash=$HOME/.bin/in-ghostty param0=ssh param1=$PIHOLE_HOST"
echo "Tailscale status | bash=$HOME/.bin/in-ghostty param0=/Applications/Tailscale.app/Contents/MacOS/Tailscale param1=status"
echo "---"
echo "Refresh | refresh=true"
