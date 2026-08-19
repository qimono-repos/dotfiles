#!/usr/bin/env bash
# Install additional console fonts and set up font cache.
# Fonts are already on Ubuntu via console-setup + kbd packages.
# This script ensures they're present and lists what's available.
set -euo pipefail

echo "=== Console Font Installer ==="

# 1) Ensure packages are installed
echo "--> Checking packages..."
PKGS_TO_INSTALL=()
for PKG in kbd console-setup console-setup-linux; do
  if ! dpkg -s "$PKG" >/dev/null 2>&1; then
    PKGS_TO_INSTALL+=("$PKG")
  fi
done

if [[ ${#PKGS_TO_INSTALL[@]} -gt 0 ]]; then
  echo "Installing: ${PKGS_TO_INSTALL[*]}"
  sudo apt update -qq
  sudo apt install -y "${PKGS_TO_INSTALL[@]}"
else
  echo "All packages already installed."
fi

# 2) Verify key fonts exist
echo ""
echo "--> Verifying fonts..."
FONT_DIR="/usr/share/consolefonts"
MISSING=0
for FONT in Lat2-TerminusBold16 Lat2-TerminusBold32x16 Lat2-TerminusBold24x12 Lat2-TerminusBold28x14; do
  if [[ -f "$FONT_DIR/${FONT}.psf.gz" ]]; then
    echo "  OK: $FONT"
  else
    echo "  MISSING: $FONT"
    MISSING=1
  fi
done

if [[ $MISSING -eq 1 ]]; then
  echo "Some fonts missing. Run: sudo apt install --reinstall kbd console-setup"
fi

# 3) Build font map if needed
echo ""
echo "--> Building console font map..."
if command -v console-setup >/dev/null 2>&1; then
  sudo dpkg-reconfigure -f noninteractive console-setup 2>/dev/null || true
  echo "OK: font map rebuilt"
else
  echo "WARN: console-setup not found, skipping font map rebuild"
fi

# 4) List available Terminus fonts
echo ""
echo "--> Available Terminus fonts:"
ls "$FONT_DIR"/Lat2-TerminusBold*.psf.gz 2>/dev/null | while read -r F; do
  NAME=$(basename "$F" .psf.gz)
  echo "  $NAME"
done

echo ""
echo "Usage:"
echo "  sudo setfont Lat2-TerminusBold32x16    # try a font now"
MY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "  sudo $MY_DIR/install-vconsole.sh    # make it permanent"
echo "  sudo $MY_DIR/console-font-resize.sh --apply  # auto-detect + set"
