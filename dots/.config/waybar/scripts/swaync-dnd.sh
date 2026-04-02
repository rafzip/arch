#!/usr/bin/env bash
set -euo pipefail

if ! command -v swaync-client >/dev/null 2>&1; then
  echo '{"text":"DND ?","tooltip":"swaync-client not found"}'
  exit 0
fi

state=$(swaync-client -D 2>/dev/null || echo false)
case "$state" in
  true)
    echo '{"text":"DND","tooltip":"Do Not Disturb enabled","class":"active"}'
    ;;
  false)
    # Hide module when DND is off
    exit 0
    ;;
  *)
    echo '{"text":"DND?","tooltip":"Do Not Disturb state: '"$state"'","class":"warning"}'
    ;;
esac
