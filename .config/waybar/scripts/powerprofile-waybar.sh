#!/usr/bin/env bash
set -euo pipefail

toggle="${1:-}"

if ! command -v powerprofilesctl >/dev/null 2>&1; then
  echo '{"text":"PP --","tooltip":"powerprofilesctl not found"}'
  exit 0
fi

# Get active profile, default to 'unknown' if empty
current="$(powerprofilesctl get 2>/dev/null || echo "unknown")"

# Improved parsing for powerprofilesctl list
mapfile -t profiles < <(powerprofilesctl list | grep -E '^[[:space:]]*\*?[[:space:]]*[a-zA-Z0-9_-]+:' | sed -E 's/^[[:space:]]*\*?[[:space:]]*//;s/:.*//')

if [ "${#profiles[@]}" -eq 0 ]; then
  echo "{\"text\":\"PP ?\",\"tooltip\":\"No profiles found. Is power-profiles-daemon running?\"}"
  exit 0
fi

next_profile() {
  local i
  for i in "${!profiles[@]}"; do
    if [ "${profiles[$i]}" = "$current" ]; then
      local next_idx=$(( (i + 1) % ${#profiles[@]} ))
      echo "${profiles[$next_idx]}"
      return
    fi
  done
  echo "${profiles[0]}"
}

if [ "$toggle" = "--toggle" ]; then
  target="$(next_profile)"
  powerprofilesctl set "$target" >/dev/null 2>&1 || true
  current="$target"
fi

# Friendly short label mapping
case "$current" in
  performance) short="perf" ;;
  balanced)    short="bal" ;;
  power-saver) short="save" ;;
  *)           short="$current" ;;
esac

# Build Tooltip
tooltip="Active: $current\n\nAvailable:\n"
for p in "${profiles[@]}"; do
  if [ "$p" = "$current" ]; then
    tooltip+="* $p\n"
  else
    tooltip+="  $p\n"
  fi
done

echo "{\"text\":\"PP ${short}\",\"tooltip\":\"${tooltip}\"}"
