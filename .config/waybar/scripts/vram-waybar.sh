#!/usr/bin/env bash
set -euo pipefail

if command -v nvidia-smi >/dev/null 2>&1; then
  used=$(nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits | head -n1 | tr -d ' ')
  total=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1 | tr -d ' ')
  echo "{\"text\":\" ${used}/${total}M\",\"tooltip\":\"VRAM used: ${used} MiB\nVRAM total: ${total} MiB\"}"
else
  echo "{\"text\":\" --\",\"tooltip\":\"nvidia-smi not found\"}"
fi
