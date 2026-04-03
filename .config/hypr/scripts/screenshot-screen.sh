#!/usr/bin/env bash
set -euo pipefail
mkdir -p ~/media/screenshots
file=~/media/screenshots/screen_$(date +%Y-%m-%d_%H-%M-%S).png
grim "$file"
wl-copy < "$file"
notify-send "Screenshot (screen)" "$file copied to clipboard"
