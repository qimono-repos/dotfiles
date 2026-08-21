#!/usr/bin/env bash
# Install vconsole.conf to /etc and apply immediately.
# Port of ubuntu-mini-pc/scripts/install-vconsole.sh (see skills/tty-console-font.md).
# Usage: sudo ./install-vconsole.sh [--font <FONT>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF_SRC="$ROOT/etc/vconsole.conf"
CONF_DST="/etc/vconsole.conf"
FONT_DIR="/usr/share/consolefonts"

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

FONT=$(grep '^FONT=' "$CONF_SRC" | cut -d= -f2)

# QA gate: verify the psf.gz actually exists BEFORE installing anything
if [[ ! -f "$FONT_DIR/${FONT}.psf.gz" ]]; then
  echo "error: $FONT_DIR/${FONT}.psf.gz missing — install console-setup-linux first:" >&2
  echo "  sudo apt install kbd console-setup console-setup-linux" >&2
  exit 1
fi
echo "--> Font file present: $FONT_DIR/${FONT}.psf.gz"

# Show what we're installing
echo "--> Config content:"
cat "$CONF_SRC"
echo ""

# Copy to /etc
cp "$CONF_SRC" "$CONF_DST"
echo "--> Installed to $CONF_DST"

# Apply immediately (expected to fail when launched from a GUI session — normal)
echo "--> Applying font: $FONT"
if setfont "$FONT" 2>/dev/null; then
  echo "OK: TTY font changed live"
else
  echo "NOTE: setfont skipped (running from GUI is expected); takes effect at boot/VT switch"
fi

# Restart systemd-vconsole-setup if available (Guix System / other distros)
if systemctl list-unit-files | grep -q systemd-vconsole-setup; then
  systemctl restart systemd-vconsole-setup 2>/dev/null || true
  echo "--> Restarted systemd-vconsole-setup"
fi

# Ubuntu persistence trap (2026-08-21): this distro ships NO
# systemd-vconsole-setup unit — console-setup.service (setupcon) owns the
# boot-time font via /etc/default/console-setup and would revert us to
# Fixed 8x16 every boot. Keep both files agreeing on the same font.
CS_DST="/etc/default/console-setup"
if [[ -f "$CS_DST" ]]; then
  cp -n "$CS_DST" "$CS_DST.bak" || true
  if grep -q '^FONT=' "$CS_DST"; then
    sed -i "s|^FONT=.*|FONT=\"$FONT\"|" "$CS_DST"
  else
    printf '\n# qimono fleet: keep in sync with /etc/vconsole.conf\nFONT="%s"\n' "$FONT" >> "$CS_DST"
  fi
  # FONT= wins over FONTFACE/FONTSIZE, but comment them out so nothing
  # disagrees later.
  sed -i 's/^FONTFACE=/#FONTFACE=/; s/^FONTSIZE=/#FONTSIZE=/' "$CS_DST"
  echo "--> Synced $CS_DST (console-setup.service applies $FONT at boot)"
fi

echo "Done. Font takes effect on next TTY login or reboot."
echo "Test now: Ctrl+Alt+F3 → see the new font → Ctrl+Alt+F1/F2 back to GNOME"
