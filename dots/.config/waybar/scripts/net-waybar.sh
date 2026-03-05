#!/usr/bin/env bash
set -euo pipefail

# Simple per-second net throughput on default route iface
iface="$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')"
if [ -z "${iface}" ]; then
  echo "{\"text\":\"NET --\",\"tooltip\":\"No default route\"}"
  exit 0
fi

rx1=$(cat "/sys/class/net/${iface}/statistics/rx_bytes")
tx1=$(cat "/sys/class/net/${iface}/statistics/tx_bytes")
sleep 1
rx2=$(cat "/sys/class/net/${iface}/statistics/rx_bytes")
tx2=$(cat "/sys/class/net/${iface}/statistics/tx_bytes")

rx=$((rx2 - rx1))
tx=$((tx2 - tx1))

hr() {
  local b="$1"
  if [ "$b" -ge 1048576 ]; then awk -v b="$b" 'BEGIN{printf "%.1fMB/s", b/1048576}'
  elif [ "$b" -ge 1024 ]; then awk -v b="$b" 'BEGIN{printf "%.0fKB/s", b/1024}'
  else echo "${b}B/s"; fi
}

echo "{\"text\":\"↓ $(hr "$rx") ↑ $(hr "$tx")\",\"tooltip\":\"Interface: ${iface}\nRX: ${rx2}\nTX: ${tx2}\"}"
