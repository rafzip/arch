#!/usr/bin/env bash
set -euo pipefail
# Usage: toggle-gpu-offload.sh <command...>
# Example: toggle-gpu-offload.sh steam

if ! command -v nvidia-smi >/dev/null 2>&1; then
  echo "nvidia-smi not found. Install nvidia-utils."
  exit 1
fi

__NV_PRIME_RENDER_OFFLOAD=1 \
__GLX_VENDOR_LIBRARY_NAME=nvidia \
__VK_LAYER_NV_optimus=NVIDIA_only \
"$@"
