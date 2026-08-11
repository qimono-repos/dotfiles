#!/usr/bin/env bash
# Allow sole user to run force reboot/poweroff without a password prompt.
# Installs /etc/sudoers.d/qimono-power (requires sudo once).
#
# Scoped narrowly: only systemctl reboot -i and poweroff -i as root.
set -euo pipefail

TARGET_USER="${SUDO_USER:-${USER:-}}"
if [[ -z "$TARGET_USER" || "$TARGET_USER" == root ]]; then
  echo "error: run as your normal user: ./scripts/install-passwordless-power.sh" >&2
  exit 1
fi

DROPIN="/etc/sudoers.d/qimono-power"
# Use absolute systemctl path; match exact argv used by ~/.zshrc.d/50-power.zsh
RULE="${TARGET_USER} ALL=(root) NOPASSWD: /usr/bin/systemctl reboot -i, /usr/bin/systemctl poweroff -i"

echo "==> Writing $DROPIN (user=$TARGET_USER)"
tmp="$(mktemp)"
printf '%s\n' \
  "# Qimono fleet — passwordless force reboot/poweroff for sole user" \
  "# Managed by: ubuntu-len-yog-AMD64/scripts/install-passwordless-power.sh" \
  "# Do not hand-edit casually; re-run the install script after changes." \
  "$RULE" \
  >"$tmp"

sudo install -m 440 -o root -g root "$tmp" "$DROPIN"
rm -f "$tmp"

if sudo visudo -cf "$DROPIN"; then
  echo "OK: $DROPIN valid"
else
  echo "error: sudoers syntax check failed; removing $DROPIN" >&2
  sudo rm -f "$DROPIN"
  exit 1
fi

echo
echo "Test (should not ask for a password for these commands):"
echo "  sudo -n -l | grep systemctl"
echo "Then from zsh:  too"
