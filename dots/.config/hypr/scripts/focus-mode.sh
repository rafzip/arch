#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-toggle}"
state_file="${XDG_RUNTIME_DIR:-/tmp}/hypr-focus-mode.state"

# Set these to match your normal config defaults:
DEFAULT_GAPS_IN=6
DEFAULT_GAPS_OUT=10
DEFAULT_ROUNDING=10

apply_focus_on() {
  # Hide waybar (toggle). Assumes you only control visibility via this script.
  pkill -USR1 waybar 2>/dev/null || true

  hyprctl --batch "\
keyword general:gaps_in 0;\
keyword general:gaps_out 0;\
keyword decoration:rounding 0\
" >/dev/null

  touch "$state_file"
}

apply_focus_off() {
  # Show waybar (toggle back)
  pkill -USR1 waybar 2>/dev/null || true

  hyprctl --batch "\
keyword general:gaps_in ${DEFAULT_GAPS_IN};\
keyword general:gaps_out ${DEFAULT_GAPS_OUT};\
keyword decoration:rounding ${DEFAULT_ROUNDING}\
" >/dev/null

  rm -f "$state_file"
}

case "$cmd" in
  on)
    [ -f "$state_file" ] || apply_focus_on
    ;;
  off)
    [ -f "$state_file" ] && apply_focus_off
    ;;
  toggle)
    if [ -f "$state_file" ]; then
      apply_focus_off
    else
      apply_focus_on
    fi
    ;;
  *)
    echo "Usage: $0 {on|off|toggle}"
    exit 1
    ;;
esac
