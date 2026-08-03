#!/usr/bin/env bash
# Host fixes: Epiphany userns + nonguix substitute trust.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY_VENDORED="$ROOT/keys/nonguix-signing-key.pub"
KEY_TMP="${TMPDIR:-/tmp}/nonguix-signing-key.pub"

echo "==> [1/2] unprivileged userns (Epiphany / WebKit bwrap)"
"$ROOT/scripts/install-host-sysctl.sh"
val="$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 1)"
if [[ "$val" != "0" ]]; then
  echo "error: userns still restricted after install-host-sysctl.sh (got $val)" >&2
  exit 1
fi
if [[ ! -f /etc/sysctl.d/99-guix-userns.conf ]]; then
  echo "error: missing /etc/sysctl.d/99-guix-userns.conf (reboot would break Epiphany)" >&2
  exit 1
fi

echo "==> [2/2] authorize substitutes.nonguix.org (Firefox binaries)"
if [[ -f "$KEY_VENDORED" ]]; then
  echo "    using vendored key: $KEY_VENDORED"
  KEY_FILE="$KEY_VENDORED"
else
  echo "    vendored key missing; curling https://substitutes.nonguix.org/signing-key.pub"
  curl -fsSL https://substitutes.nonguix.org/signing-key.pub -o "$KEY_TMP"
  KEY_FILE="$KEY_TMP"
fi

# guix archive --authorize needs a guix that can talk to the store
export PATH="${HOME}/.config/guix/current/bin:/usr/local/bin:${PATH:-}"
hash -r 2>/dev/null || true
sudo "$(command -v guix)" archive --authorize < "$KEY_FILE" \
  || sudo guix archive --authorize < "$KEY_FILE"

echo "OK: browser host prereqs (userns=0 + nonguix key authorized)"
