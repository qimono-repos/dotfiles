#!/usr/bin/env bash
# =============================================================================
# finish-guix-binary.sh — complete the Guix foreign-distro binary install.
#
# The Guix 1.5.0 *aarch64* binary tarball ships the guix binary at
# /var/guix/profiles/per-user/root/current-guix/bin/guix but does NOT create
# /usr/local/bin/guix, does NOT ship a systemd unit, and does NOT auto-authorize
# the substitute signing keys. This script finishes those three things.
#
# Run with sudo once after ./install-guix-binary.sh:
#   sudo ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-ARM64/scripts/finish-guix-binary.sh
# =============================================================================
set -euo pipefail

GUIX_ROOT="/var/guix/profiles/per-user/root/current-guix"
GUIX="$GUIX_ROOT/bin/guix"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "error: run with sudo." >&2
  exit 1
fi

if [[ ! -x "$GUIX" ]]; then
  echo "error: $GUIX not found — run install-guix-binary.sh first." >&2
  exit 1
fi

echo "==> GNU Guix at: $GUIX_ROOT"

echo
echo "[1/5] Create /usr/local/bin/guix convenience symlink"
if [[ -e /usr/local/bin/guix ]]; then
  rm -f /usr/local/bin/guix
fi
ln -s "$GUIX" /usr/local/bin/guix
/usr/local/bin/guix --version | head -1

echo
echo "[2/5] Authorize official substitute signing keys"
for keyname in bordeaux.guix.gnu.org ci.guix.gnu.org berlin.guix.gnu.org; do
  keyfile="$GUIX_ROOT/share/guix/$keyname.pub"
  if [[ -f "$keyfile" ]]; then
    "$GUIX" archive --authorize < "$keyfile"
  else
    echo "   (skip: no key $keyfile)"
  fi
done

echo
echo "[3/5] Install + enable guix-daemon systemd service (root run, now)"
UNIT="/etc/systemd/system/guix-daemon.service"
cat > "$UNIT" <<'EOF'
[Unit]
Description=Guix build daemon
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/var/guix/profiles/per-user/root/current-guix/bin/guix-daemon --build-users-group=guixbuild --discover=no --substitute-urls='https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable guix-daemon.service
systemctl start guix-daemon.service

echo
echo "[4/5] Verify daemon running"
sleep 2
if pgrep -x guix-daemon >/dev/null 2>&1; then
  echo "   guix-daemon is running."
else
  echo "   WARN: guix-daemon not detected. Check: systemctl status guix-daemon"
fi
systemctl is-enabled guix-daemon.service 2>/dev/null || true

echo
echo "[5/5] Verify from the user account (ni means daemon answers)"
runuser -l qi -c "/usr/local/bin/guix describe" 2>&1 | head -3 || true

echo
echo "==========================================================="
echo " DONE — Guix daemon up, keys authorized, guix on /usr/local/bin."
echo " Continue (as qi, no sudo):"
echo "   cd ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-ARM64"
echo "   ./scripts/install-host-sysctl.sh       # userns=0 (needs sudo once)"
echo "   ./scripts/install-guix-python-uv.sh    # uv, python, stow into profile"
echo "   ./scripts/stow-apply.sh                # dotfiles -> \$HOME"
echo "==========================================================="
