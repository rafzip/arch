#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  up) brightnessctl -d amdgpu_bl2 set +5% >/dev/null ;;
  down) brightnessctl -d amdgpu_bl2 set 5%- >/dev/null ;;
  *) ;;
esac

current=$(brightnessctl -d amdgpu_bl2 get)
max=$(brightnessctl -d amdgpu_bl2 max)
percent=$(( current * 100 / max ))

id_file="${XDG_RUNTIME_DIR:-/tmp}/brightness-osd-notify.id"
replace_id=0
if [[ -f "$id_file" ]]; then
  replace_id=$(<"$id_file")
fi

new_id=$(notify-send -p -r "$replace_id" "Brightness" "Brightness: ${percent}%")
printf '%s' "$new_id" > "$id_file"
