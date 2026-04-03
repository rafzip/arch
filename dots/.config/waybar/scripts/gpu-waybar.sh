#!/usr/bin/env bash

set -euo pipefail

# Fast fallback output
fallback() {
echo '{"text":"󰌢 dGPU off","tooltip":"NVIDIA GPU unavailable or powered down"}'
}

# No nvidia-smi installed
command -v nvidia-smi >/dev/null 2>&1 || { fallback; exit 0; }
command -v timeout >/dev/null 2>&1 || { fallback; exit 0; }

# Kill nvidia-smi if it takes too long
line="$(
timeout 0.5s nvidia-smi \
--query-gpu=utilization.gpu,temperature.gpu,power.draw,name \
--format=csv,noheader,nounits 2>/dev/null \
| head -n1
)" || {
fallback
exit 0
}

# Empty output = no usable GPU
[ -n "${line:-}" ] || {
fallback
exit 0
}

IFS=',' read -r util temp pwr name <<< "$line"

trim() { xargs <<< "${1:-}"; }

util="$(trim "$util")"
temp="$(trim "$temp")"
pwr="$(trim "$pwr")"
name="$(trim "$name")"

printf '{"text":"󰢮 %s%%","tooltip":"%s\nTemp: %s°C\nPower: %sW"}\n' \
"$util" "$name" "$temp" "$pwr"