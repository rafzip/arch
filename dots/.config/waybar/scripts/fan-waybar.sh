#!/usr/bin/env bash
set -euo pipefail

# Generic hwmon fan read (best-effort)
fan_file="$(grep -Rl "fan" /sys/class/hwmon/*/name 2>/dev/null | head -n1 || true)"
# Fallback: search for fan*_input
rpm_path="$(ls -1 /sys/class/hwmon/hwmon*/fan*_input 2>/dev/null | head -n1 || true)"

if [ -n "${rpm_path}" ] && [ -r "${rpm_path}" ]; then
  rpm=$(cat "${rpm_path}")
  echo "{\"text\":\"FAN ${rpm}rpm\",\"tooltip\":\"Source: ${rpm_path}\"}"
else
  echo "{\"text\":\"FAN --\",\"tooltip\":\"No fan sensor found\"}"
fi
