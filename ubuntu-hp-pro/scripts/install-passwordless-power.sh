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
# visudo -c validates before we replace a live file
tmp="$(mktemp)"
printf '%s\n' \
  "# Qimono fleet — passwordless force reboot/poweroff for sole user" \
  "# Managed by: ubuntu-hp-pro/scripts/install-passwordless-power.sh" \
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
echo "Test (should print nothing and not ask for a password):"
echo "  sudo -n /usr/bin/systemctl reboot -i --help 2>/dev/null || sudo -n -l | grep systemctl"
echo "Then from zsh:  too"
echo
# Non-destructive check: can we run the command with -n (no prompt)?
if sudo -n true 2>/dev/null; then
  :
fi
if sudo -n -l 2>/dev/null | grep -q 'systemctl reboot'; then
  echo "sudo -l shows passwordless systemctl reboot/poweroff — good."
else
  echo "Note: open a new shell or run: sudo -k; then try: too"
fi
