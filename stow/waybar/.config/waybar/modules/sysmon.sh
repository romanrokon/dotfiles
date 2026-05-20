#!/bin/bash
# Waybar custom module: CPU/RAM/temp sysmon.

WARN_PCT=70
CRIT_PCT=90
WARN_TEMP=70
CRIT_TEMP=85

# CPU load → % (load/ncores * 100)
NCPU=$(nproc)
LOAD1=$(awk '{print $1}' /proc/loadavg)
CPU_PCT=$(awk -v l="$LOAD1" -v n="$NCPU" 'BEGIN{printf "%.0f", l/n*100}')

# RAM
RAM_PCT=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%.0f", (t-a)*100/t}' /proc/meminfo)
RAM_USED_GB=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf "%.1f", (t-a)/1048576}')
RAM_TOTAL_GB=$(awk '/MemTotal/{printf "%.0f", $2/1048576}' /proc/meminfo)

# Swap
SWAP_USED_GB=$(awk '/SwapTotal/{t=$2} /SwapFree/{f=$2} END{printf "%.1f", (t-f)/1048576}' /proc/meminfo)

# Temp (highest)
CPU_TEMP="?"
if command -v sensors >/dev/null 2>&1; then
  CPU_TEMP=$(sensors -u 2>/dev/null | awk -F': ' '/_input/ && /temp/ {print $2}' | sort -rn | head -1 | awk '{printf "%.0f", $1}')
  [ -z "$CPU_TEMP" ] && CPU_TEMP="?"
fi

CLASS="ok"
if [ "$CPU_PCT" -ge "$CRIT_PCT" ] || [ "$RAM_PCT" -ge "$CRIT_PCT" ]; then CLASS="error"
elif [ "$CPU_PCT" -ge "$WARN_PCT" ] || [ "$RAM_PCT" -ge "$WARN_PCT" ]; then CLASS="warn"
fi
[ "$CPU_TEMP" != "?" ] && [ "${CPU_TEMP%.*}" -ge "$CRIT_TEMP" ] && CLASS="error"

TEXT="󰍛 ${CPU_PCT}% ${RAM_PCT}%"
TOOLTIP="CPU ${CPU_PCT}% | RAM ${RAM_PCT}% (${RAM_USED_GB}/${RAM_TOTAL_GB} GB)\nSwap ${SWAP_USED_GB} GB | Temp ${CPU_TEMP}°C"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$TEXT" "${TOOLTIP//$'\n'/\\n}" "$CLASS"
