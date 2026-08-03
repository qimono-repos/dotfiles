#!/usr/bin/env bash
# Install pack host sysctl so Guix bubblewrap sandboxes work after reboot.
# Idempotent. Needs sudo once.
#
# Fixes: bwrap: setting up uid map: Permission denied (Epiphany/WebKit, etc.)
# See: host-sysctl/99-guix-userns.conf · docs/LESSONS.md
# Sibling: ubuntu-len-yog-AMD64/scripts/install-host-sysctl.sh (keep in sync)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/host-sysctl/99-guix-userns.conf"
DST="/etc/sysctl.d/99-guix-userns.conf"
LEGACY_DST="/etc/sysctl.d/99-apparmor-userns.conf"

if [[ ! -f "$SRC" ]]; then
  echo "error: missing $SRC" >&2
  exit 1
fi

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=()
else
  SUDO=(sudo)
fi

echo "==> install host sysctl for Guix userns (AppArmor gate off)"
echo "    source: $SRC"
echo "    dest:   $DST"

before="$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo '?')"
echo "    before: apparmor_restrict_unprivileged_userns=$before"

"${SUDO[@]}" cp "$SRC" "$DST"
"${SUDO[@]}" sysctl -p "$DST"

if [[ -f "$LEGACY_DST" ]]; then
  echo "    removing legacy $LEGACY_DST (pack uses 99-guix-userns.conf)"
  "${SUDO[@]}" rm -f "$LEGACY_DST"
fi

after="$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns)"
echo "    after:  apparmor_restrict_unprivileged_userns=$after (want 0)"

if [[ "$after" != "0" ]]; then
  echo "error: userns still restricted after install" >&2
  exit 1
fi

echo "OK: $DST installed; survives reboot."
echo "    verify after reboot: sysctl kernel.apparmor_restrict_unprivileged_userns"
echo "    smoke: epiphany &"
