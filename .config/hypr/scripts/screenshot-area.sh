#!/usr/bin/env bash
set -euo pipefail
mkdir -p ~/media/screenshots
file=~/media/screenshots/area_$(date +%Y-%m-%d_%H-%M-%S).png
grim -g "$(slurp)" "$file"
wl-copy < "$file"
notify-send "Screenshot (area)" "$file copied to clipboard"
