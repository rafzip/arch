#!/usr/bin/env bash
set -euo pipefail

# Battery power draw (works on many laptops): /sys/class/power_supply/BAT*/power_now in uW
bat="$(ls -1 /sys/class/power_supply 2>/dev/null | grep -E '^BAT' | head -n1 || true)"
if [ -n "${bat}" ] && [ -r "/sys/class/power_supply/${bat}/power_now" ]; then
  uw=$(cat "/sys/class/power_supply/${bat}/power_now")
  w=$(awk -v uw="$uw" 'BEGIN { printf "%.1f", uw/1000000 }')
  st=$(cat "/sys/class/power_supply/${bat}/status" 2>/dev/null || echo "")
  echo "{\"text\":\"PWR ${w}W\",\"tooltip\":\"Battery: ${bat}\nStatus: ${st}\nDraw: ${w} W\"}"
else
  echo "{\"text\":\"PWR --\",\"tooltip\":\"No power_now found\"}"
fi
