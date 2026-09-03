#!/usr/bin/env bash
# apply-grub.sh — install the Qimono GRUB dual-boot drop-ins on the Yoga.
# NEEDS SUDO (writes /etc). Run from a terminal with a password:
#   sudo ./scripts/apply-grub.sh
#
# Copies:
#   grub/stow-source/etc/default/grub.d/99-qimono-grub.cfg
#                   -> /etc/default/grub.d/99-qimono-grub.cfg
#   (40_custom.windows-chainload is a TEMPLATE — see step 2, append manually)
#
# Then runs `sudo update-grub`. On aarch64 os-prober will probe for Windows.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/grub/stow-source"

if [[ "$(id -u)" != "0" ]]; then
  echo "run as root:  sudo $0" >&2
  exit 1
fi

echo "=== Qimono GRUB dual-boot apply (Yoga aarch64) ==="

# 1) default drop-in
install -D -m 0644 \
  "$SRC/etc/default/grub.d/99-qimono-grub.cfg" \
  /etc/default/grub.d/99-qimono-grub.cfg
echo "  → /etc/default/grub.d/99-qimono-grub.cfg installed"

# 2) Windows chainload template (APPEND manually — it needs your ESP UUID)
if [[ -f "$SRC/etc/grub.d/40_custom.windows-chainload" ]]; then
  echo
  echo "STEP 2 (manual): append this to /etc/grub.d/40_custom:"
  echo
  cat "$SRC/etc/grub.d/40_custom.windows-chainload"
  echo
fi

# 3) regenerate GRUB (probes Windows via os-prober)
echo "Running: sudo update-grub ..."
update-grub

echo
echo "Done. Reboot to see the new menu."
echo "If Windows is missing, run:  sudo os-prober   then  sudo update-grub"
