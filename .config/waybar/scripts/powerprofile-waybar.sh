#!/usr/bin/env bash
set -euo pipefail

toggle="${1:-}"

if ! command -v powerprofilesctl >/dev/null 2>&1; then
  echo '{"text":"PP --","tooltip":"powerprofilesctl not found (install power-profiles-daemon)"}'
  exit 0
fi

current="$(powerprofilesctl get 2>/dev/null || true)"

# powerprofilesctl list output contains profile names like:
# * performance:
#   balanced:
#   power-saver:
mapfile -t profiles < <(powerprofilesctl list 2>/dev/null | awk -F: '/^[ *]?[a-z-]+:/ {gsub(/^[ *]/,"",$1); print $1}')

if [ "${#profiles[@]}" -eq 0 ]; then
  echo "{\"text\":\"PP ?\",\"tooltip\":\"No profiles returned by powerprofilesctl list\"}"
  exit 0
fi

next_profile() {
  local i
  for i in "${!profiles[@]}"; do
    if [ "${profiles[$i]}" = "$current" ]; then
      echo "${profiles[$(( (i + 1) % ${#profiles[@]} ))]}"
      return
    fi
  done
  # If current not in list, pick first
  echo "${profiles[0]}"
}

if [ "$toggle" = "--toggle" ]; then
  target="$(next_profile)"
  powerprofilesctl set "$target" >/dev/null 2>&1 || true
  current="$(powerprofilesctl get 2>/dev/null || echo "$target")"
fi

# Friendly short label
short="$current"
case "$current" in
  performance) short="perf" ;;
  balanced) short="bal" ;;
  power-saver) short="save" ;;
esac

tooltip="Available profiles:\n"
for p in "${profiles[@]}"; do
  if [ "$p" = "$current" ]; then
    tooltip+="- * $p (active)\n"
  else
    tooltip+="- $p\n"
  fi
done
tooltip+="\nClick to cycle."

echo "{\"text\":\"PP ${short}\",\"tooltip\":\"${tooltip}\"}"
