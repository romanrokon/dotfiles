#!/bin/bash
# SwiftBar plugin: Pi-hole over Tailscale status.
# Refresh every 30s.
#
# <swiftbar.title>Pi-hole</swiftbar.title>
# <swiftbar.desc>DNS + HTTP liveness probe for orangepi-pihole over Tailscale</swiftbar.desc>
# <swiftbar.dependencies>dig,curl,tailscale</swiftbar.dependencies>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/sbin:/usr/bin:/bin:$PATH"

PIHOLE_HOST="orangepi-pihole.monster-barley.ts.net"
PIHOLE_IP="100.100.1.1"
PROBE_DOMAIN="google.com"
TIMEOUT=2
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
echo "Ping pihole | bash=ping param0=-c param1=4 param2=$PIHOLE_IP terminal=true"
echo "SSH to pihole | bash=ssh param0=$PIHOLE_HOST terminal=true"
echo "Tailscale status | bash=/Applications/Tailscale.app/Contents/MacOS/Tailscale param0=status terminal=true"
echo "---"
echo "Refresh | refresh=true"
