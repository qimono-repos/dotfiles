#!/usr/bin/env bash
# Fix Epiphany/WebKit bwrap on Ubuntu (AppArmor unprivileged userns restriction).
# Requires sudo. Safe for personal laptop; see docs/guix-browsers-foreign-distro.md
set -euo pipefail

echo "Current: kernel.apparmor_restrict_unprivileged_userns=$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns)"

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

$SUDO sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
echo 'kernel.apparmor_restrict_unprivileged_userns=0' | $SUDO tee /etc/sysctl.d/99-guix-userns.conf >/dev/null
echo "Wrote /etc/sysctl.d/99-guix-userns.conf (survives reboot)."
echo "Now: source ~/.guix-profile/etc/profile && epiphany &"
