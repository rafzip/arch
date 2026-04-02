#!/usr/bin/env bash
set -euo pipefail

# NVIDIA usage (if nvidia-smi exists), else show iGPU placeholder.
if command -v nvidia-smi >/dev/null 2>&1; then
  util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1 | tr -d ' ')
  temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits | head -n1 | tr -d ' ')
  pwr=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits | head -n1 | tr -d ' ')
  name=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
  echo "{\"text\":\" ${util}%\",\"tooltip\":\"${name}\nTemp: ${temp}°C\nPower: ${pwr}W\"}"
else
  echo "{\"text\":\" iGPU\",\"tooltip\":\"nvidia-smi not found\"}"
fi
