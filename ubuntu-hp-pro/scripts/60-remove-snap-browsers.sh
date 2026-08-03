#!/usr/bin/env bash
# Remove snap Firefox / Epiphany if present (Guix browsers replace them).
set -euo pipefail

if ! command -v snap >/dev/null 2>&1; then
  echo "snap not installed; skip"
  exit 0
fi

remove_if_present() {
  local name="$1"
  if snap list "$name" >/dev/null 2>&1; then
    echo "Removing snap: $name"
    sudo snap remove "$name" || echo "WARN: could not remove $name"
  else
    echo "snap $name not installed; skip"
  fi
}

# Common names
remove_if_present firefox
remove_if_present epiphany

# Some spins use different names — list for the human
echo "Remaining browser-ish snaps (if any):"
snap list 2>/dev/null | grep -iE 'firefox|epiphany|chromium|brave|chrome' || echo "(none matched)"

echo "OK: snap browser cleanup attempted"
echo "NOTE: Keep another browser (Chrome/Brave) until you verify Guix Firefox + Epiphany open pages."
