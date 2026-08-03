#!/usr/bin/env bash
# Install GNU Guix if missing (official installer, noninteractive where possible).
set -euo pipefail

if command -v guix >/dev/null 2>&1; then
  echo "OK: guix already present: $(command -v guix)"
  guix --version | head -1 || true
  exit 0
fi

echo "==> Installing GNU Guix (official installer)…"
echo "    You will be prompted for sudo if needed."
TMP="${TMPDIR:-/tmp}/guix-install-$$"
mkdir -p "$TMP"
# Official installer
wget -q -O "$TMP/guix-install.sh" https://guix.gnu.org/guix-install.sh
chmod +x "$TMP/guix-install.sh"

# Noninteractive defaults when supported by installer
export YES_TO_ALL="${YES_TO_ALL:-1}"
sudo --preserve-env=YES_TO_ALL env YES_TO_ALL=1 "$TMP/guix-install.sh" || {
  echo "WARN: noninteractive install returned non-zero; trying interactive…"
  sudo "$TMP/guix-install.sh"
}

# Ensure daemon up
if systemctl list-unit-files 2>/dev/null | grep -q guix-daemon; then
  sudo systemctl enable --now guix-daemon 2>/dev/null || true
fi

hash -r 2>/dev/null || true
if ! command -v guix >/dev/null 2>&1; then
  export PATH="/usr/local/bin:$PATH"
fi
command -v guix
guix --version | head -1
echo "OK: Guix installed (run guix pull next for nonguix/firefox)"
