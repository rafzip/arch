#!/usr/bin/env bash
set -euo pipefail
mkdir -p ~/Pictures/Screenshots
file=~/Pictures/Screenshots/screen_$(date +%Y-%m-%d_%H-%M-%S).png
grim "$file"
wl-copy < "$file"
notify-send "Screenshot (screen)" "$file copied to clipboard"
