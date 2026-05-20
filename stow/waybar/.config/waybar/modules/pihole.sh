#!/bin/bash
# Waybar custom module: Pi-hole over Tailscale liveness.
# JSON {text, tooltip, class}.

# Defaults; override via ~/.config/dotfiles/pihole.env (kept in private repo).
PIHOLE_HOST=""
PIHOLE_IP=""
PROBE_DOMAIN="google.com"
TIMEOUT=2

PIHOLE_ENV="$HOME/.config/dotfiles/pihole.env"
[ -f "$PIHOLE_ENV" ] && . "$PIHOLE_ENV"

if [ -z "$PIHOLE_IP" ]; then
  echo '{"text":"󰒙 ?","tooltip":"Create ~/.config/dotfiles/pihole.env with PIHOLE_IP and PIHOLE_HOST","class":"off"}'
  exit 0
fi

# Tailscale state
TS_UP=0
if command -v tailscale >/dev/null 2>&1; then
  if tailscale status --json 2>/dev/null | grep -Eq '"BackendState":\s*"Running"'; then
    TS_UP=1
  fi
fi

if [ "$TS_UP" = 0 ]; then
  echo '{"text":"󰒘 TS off","tooltip":"Tailscale not running","class":"off"}'
  exit 0
fi

# DNS
START=$(date +%s%N)
ANSWER=$(dig +short +time=$TIMEOUT +tries=1 @"$PIHOLE_IP" "$PROBE_DOMAIN" 2>/dev/null | head -1)
END=$(date +%s%N)
DNS_MS=$(( (END - START) / 1000000 ))
DNS_OK=0
[[ "$ANSWER" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && DNS_OK=1

# HTTP
HTTP_CODE=$(curl -s -o /dev/null -m $TIMEOUT -w "%{http_code}" "http://$PIHOLE_IP/admin" 2>/dev/null)
HTTP_OK=0
[[ "$HTTP_CODE" =~ ^(200|301|302|307|308)$ ]] && HTTP_OK=1

if [ "$DNS_OK" = 1 ] && [ "$HTTP_OK" = 1 ]; then
  TEXT="󰒘 ${DNS_MS}ms"
  CLASS="ok"
elif [ "$DNS_OK" = 1 ] || [ "$HTTP_OK" = 1 ]; then
  TEXT="󰒙 partial"
  CLASS="warn"
else
  TEXT="󰒙 down"
  CLASS="error"
fi

TOOLTIP="Pi-hole @ $PIHOLE_HOST\nDNS: $([ $DNS_OK = 1 ] && echo OK || echo FAIL) (${DNS_MS}ms)\nHTTP: $HTTP_CODE"
printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$TEXT" "$TOOLTIP" "$CLASS"
