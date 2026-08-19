#!/usr/bin/env bash
# Install vconsole.conf to /etc and apply immediately.
# Usage: sudo ./install-vconsole.sh [--font <FONT>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF_SRC="$ROOT/etc/vconsole.conf"
CONF_DST="/etc/vconsole.conf"

echo "=== vconsole.conf installer ==="

# Parse optional --font flag to override the font in the config
FONT_OVERRIDE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --font) FONT_OVERRIDE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

# Check root
if [[ $EUID -ne 0 ]]; then
  echo "error: must run as root (sudo)" >&2
  exit 1
fi

# Source config
if [[ ! -f "$CONF_SRC" ]]; then
  echo "error: $CONF_SRC not found" >&2
  exit 1
fi

# Apply font override if given
if [[ -n "$FONT_OVERRIDE" ]]; then
  echo "--> Overriding font to: $FONT_OVERRIDE"
  sed -i "s/^FONT=.*/FONT=$FONT_OVERRIDE/" "$CONF_SRC"
fi

# Show what we're installing
echo "--> Config content:"
cat "$CONF_SRC"
echo ""

# Copy to /etc
cp "$CONF_SRC" "$CONF_DST"
echo "--> Installed to $CONF_DST"

# Apply immediately
if command -v setfont >/dev/null 2>&1; then
  FONT=$(grep '^FONT=' "$CONF_DST" | cut -d= -f2)
  echo "--> Applying font: $FONT"
  setfont "$FONT" 2>/dev/null && echo "OK: TTY font changed" || echo "WARN: setfont failed (normal if not on a TTY)"
fi

# Restart systemd-vconsole-setup if available
if systemctl list-unit-files | grep -q systemd-vconsole-setup; then
  systemctl restart systemd-vconsole-setup 2>/dev/null || true
  echo "--> Restarted systemd-vconsole-setup"
fi

echo "Done. Font takes effect on next TTY login or reboot."
echo "Test now: Ctrl+Alt+F3 → see the new font → Ctrl+Alt+F7 to return"
