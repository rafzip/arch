#!/usr/bin/env sh

set -eu

# Reload Hyprland config first so updated binds/settings are applied.
hyprctl reload

# Restart waybar cleanly.
pkill -x waybar 2>/dev/null || true
nohup waybar >/dev/null 2>&1 &
