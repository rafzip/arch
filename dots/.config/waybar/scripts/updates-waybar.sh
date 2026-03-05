#!/usr/bin/env bash
set -euo pipefail

# Requires: pacman-contrib (checkupdates)
if command -v checkupdates >/dev/null 2>&1; then
  count=$(checkupdates 2>/dev/null | wc -l | tr -d ' ')
  echo "{\"text\":\"UPD ${count}\",\"tooltip\":\"Arch updates available: ${count}\"}"
else
  echo "{\"text\":\"UPD --\",\"tooltip\":\"Install pacman-contrib for checkupdates\"}"
fi
