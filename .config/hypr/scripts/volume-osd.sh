#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  up) pactl set-sink-volume @DEFAULT_SINK@ +3% ;;
  down) pactl set-sink-volume @DEFAULT_SINK@ -3% ;;
  mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
  *) ;;
esac

vol=$(pactl get-sink-volume @DEFAULT_SINK@ | awk '{print $5}' | head -n1)
muted=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

id_file="${XDG_RUNTIME_DIR:-/tmp}/volume-osd-notify.id"
replace_id=0
if [[ -f "$id_file" ]]; then
  replace_id=$(<"$id_file")
fi

new_id=$(notify-send -p -r "$replace_id" "Volume" "Volume: ${vol} (muted: ${muted})")
printf '%s' "$new_id" > "$id_file"
