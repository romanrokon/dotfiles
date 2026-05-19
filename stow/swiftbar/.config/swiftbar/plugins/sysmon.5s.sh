#!/bin/bash
# SwiftBar plugin: system monitor (CPU/RAM/swap/temp/battery).
# Refresh every 5s.
#
# <swiftbar.title>SysMon</swiftbar.title>
# <swiftbar.desc>CPU/RAM/swap/temp/battery at a glance</swiftbar.desc>
# <swiftbar.dependencies>smctemp,top,vm_stat,sysctl,pmset</swiftbar.dependencies>

export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

WARN_PCT=70
CRIT_PCT=90
WARN_TEMP=70
CRIT_TEMP=85

# --- CPU load (load avg / core count) ---
NCPU=$(sysctl -n hw.ncpu)
LOAD1=$(sysctl -n vm.loadavg | awk '{print $2}')
LOAD5=$(sysctl -n vm.loadavg | awk '{print $3}')
# Load as % of all cores (>100 means oversubscribed)
CPU_PCT=$(awk -v l="$LOAD1" -v n="$NCPU" 'BEGIN{printf "%.0f", l/n*100}')

# --- RAM % ---
TOTAL_BYTES=$(sysctl -n hw.memsize)
PAGE_SIZE=$(sysctl -n hw.pagesize)
RAM_USED_BYTES=$(vm_stat | awk -v ps="$PAGE_SIZE" '
  /Pages active/   {gsub(/\./,"",$3); a=$3}
  /Pages wired/    {gsub(/\./,"",$4); w=$4}
  /Pages occupied/ {gsub(/\./,"",$5); c=$5}
  END {print (a+w+c)*ps}')
RAM_PCT=$(awk -v u="$RAM_USED_BYTES" -v t="$TOTAL_BYTES" 'BEGIN{printf "%.0f", u*100/t}')
RAM_USED_GB=$(awk -v b="$RAM_USED_BYTES" 'BEGIN{printf "%.1f", b/1073741824}')
RAM_TOTAL_GB=$(awk -v b="$TOTAL_BYTES" 'BEGIN{printf "%.0f", b/1073741824}')

# --- Swap ---
SWAP_LINE=$(sysctl -n vm.swapusage)
SWAP_USED=$(echo "$SWAP_LINE" | awk '{print $6}' | sed 's/M$//')
SWAP_TOTAL=$(echo "$SWAP_LINE" | awk '{print $3}' | sed 's/M$//')
SWAP_USED_GB=$(awk -v m="$SWAP_USED" 'BEGIN{printf "%.1f", m/1024}')
SWAP_TOTAL_GB=$(awk -v m="$SWAP_TOTAL" 'BEGIN{printf "%.0f", m/1024}')

# --- Temp ---
CPU_TEMP=$(smctemp -c -n 2 2>/dev/null | head -1)
GPU_TEMP=$(smctemp -g -n 2 2>/dev/null | head -1)
[ -z "$CPU_TEMP" ] && CPU_TEMP="?"
[ -z "$GPU_TEMP" ] && GPU_TEMP="?"

# --- Battery ---
BATT_LINE=$(pmset -g batt | tail -1)
BATT_PCT=$(echo "$BATT_LINE" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
BATT_STATE=$(echo "$BATT_LINE" | awk '{print $4}' | tr -d ';')
BATT_TIME=$(echo "$BATT_LINE" | grep -oE '[0-9]+:[0-9]+' | head -1)
BATT_ICON="🔋"
if echo "$BATT_LINE" | grep -q "AC Power\|charging\|charged"; then BATT_ICON="🔌"; fi

# --- Menubar text ---
# CPU + RAM compact, color on threshold
MENU="🖥 ${CPU_PCT}% ${RAM_PCT}%"
COLOR=""
if [ -n "$CPU_PCT" ] && [ "$CPU_PCT" -ge "$CRIT_PCT" ]; then COLOR="red"
elif [ -n "$CPU_PCT" ] && [ "$CPU_PCT" -ge "$WARN_PCT" ]; then COLOR="orange"
elif [ -n "$RAM_PCT" ] && [ "$RAM_PCT" -ge "$CRIT_PCT" ]; then COLOR="red"
elif [ -n "$RAM_PCT" ] && [ "$RAM_PCT" -ge "$WARN_PCT" ]; then COLOR="orange"
fi
if [ -n "$COLOR" ]; then echo "$MENU | color=$COLOR"; else echo "$MENU"; fi

echo "---"

# --- CPU section ---
CPU_TEMP_INT=${CPU_TEMP%.*}
CPU_TEMP_COLOR=""
if [ "$CPU_TEMP_INT" != "?" ] && [ "${CPU_TEMP_INT:-0}" -ge "$CRIT_TEMP" ]; then CPU_TEMP_COLOR="red"
elif [ "$CPU_TEMP_INT" != "?" ] && [ "${CPU_TEMP_INT:-0}" -ge "$WARN_TEMP" ]; then CPU_TEMP_COLOR="orange"
fi
TEMP_LINE="🌡 CPU ${CPU_TEMP}°C   GPU ${GPU_TEMP}°C"
if [ -n "$CPU_TEMP_COLOR" ]; then
  echo "$TEMP_LINE | color=$CPU_TEMP_COLOR"
else
  echo "$TEMP_LINE"
fi

echo "💻 CPU ${CPU_PCT}%"
echo "🧠 RAM ${RAM_PCT}%  (${RAM_USED_GB} / ${RAM_TOTAL_GB} GB)"

# Swap line — color if > 0
if (( $(awk -v s="$SWAP_USED_GB" 'BEGIN{print (s > 1)}') )); then
  echo "💾 Swap ${SWAP_USED_GB} / ${SWAP_TOTAL_GB} GB | color=orange"
else
  echo "💾 Swap ${SWAP_USED_GB} / ${SWAP_TOTAL_GB} GB"
fi

# Battery
if [ -n "$BATT_PCT" ]; then
  BATT_COLOR=""
  [ "$BATT_PCT" -le 20 ] && [ "$BATT_ICON" = "🔋" ] && BATT_COLOR="red"
  [ "$BATT_PCT" -le 40 ] && [ "$BATT_ICON" = "🔋" ] && [ -z "$BATT_COLOR" ] && BATT_COLOR="orange"
  LINE="${BATT_ICON} Battery ${BATT_PCT}%"
  [ -n "$BATT_TIME" ] && LINE="${LINE} (${BATT_TIME})"
  if [ -n "$BATT_COLOR" ]; then echo "$LINE | color=$BATT_COLOR"; else echo "$LINE"; fi
fi

echo "---"

# --- Actions ---
echo "🧊 Cooldown (kill daemons + purge) | bash=$HOME/.bin/cooldown terminal=true refresh=true"
echo "📊 Open Activity Monitor | bash=open param0=-a param1=Activity\\ Monitor terminal=false"
echo "🔄 Refresh | refresh=true"
