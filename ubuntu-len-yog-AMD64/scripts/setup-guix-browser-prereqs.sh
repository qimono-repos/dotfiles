#!/usr/bin/env bash
# One-time host prereqs so Guix Epiphany + Firefox work on Ubuntu (foreign distro).
# Needs sudo once. Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYSCTL_SRC="$ROOT/host-sysctl/99-guix-userns.conf"
KEY_URL="https://substitutes.nonguix.org/signing-key.pub"
KEY_TMP="${TMPDIR:-/tmp}/nonguix-signing-key.pub"

echo "==> [1/2] Ubuntu userns (Epiphany / WebKit bwrap)"
if [[ ! -f "$SYSCTL_SRC" ]]; then
  echo "error: missing $SYSCTL_SRC" >&2
  exit 1
fi
sudo cp "$SYSCTL_SRC" /etc/sysctl.d/99-guix-userns.conf
sudo sysctl -p /etc/sysctl.d/99-guix-userns.conf
echo "    apparmor_restrict_unprivileged_userns=$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns) (want 0)"

echo "==> [2/2] Authorize nonguix substitute signing key (Firefox binaries)"
curl -fsSL "$KEY_URL" -o "$KEY_TMP"
sudo guix archive --authorize < "$KEY_TMP"
echo "    authorized $KEY_URL"

echo
echo "OK prereqs. Next:"
echo "  export PATH=\"\$HOME/.config/guix/current/bin:\$PATH\" && hash guix"
echo "  which guix   # must be …/current/bin/guix"
echo "  ./scripts/setup-guix-browsers-first-try.sh install"
echo "See docs/LESSONS-guix-browsers.md"
