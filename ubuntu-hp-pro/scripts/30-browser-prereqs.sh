#!/usr/bin/env bash
# Host fixes: Epiphany userns + nonguix substitute trust.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SYSCTL_SRC="$ROOT/host-sysctl/99-guix-userns.conf"
KEY_TMP="${TMPDIR:-/tmp}/nonguix-signing-key.pub"

echo "==> [1/2] unprivileged userns (Epiphany / WebKit bwrap)"
sudo cp "$SYSCTL_SRC" /etc/sysctl.d/99-guix-userns.conf
sudo sysctl -p /etc/sysctl.d/99-guix-userns.conf
val="$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns)"
echo "    apparmor_restrict_unprivileged_userns=$val (want 0)"
if [[ "$val" != "0" ]]; then
  echo "error: userns still restricted" >&2
  exit 1
fi

echo "==> [2/2] authorize substitutes.nonguix.org (Firefox binaries)"
curl -fsSL https://substitutes.nonguix.org/signing-key.pub -o "$KEY_TMP"
# guix archive --authorize needs the guix that can talk to the store
export PATH="${HOME}/.config/guix/current/bin:/usr/local/bin:${PATH:-}"
hash -r 2>/dev/null || true
sudo "$(command -v guix)" archive --authorize < "$KEY_TMP" \
  || sudo guix archive --authorize < "$KEY_TMP"

echo "OK: browser host prereqs"
