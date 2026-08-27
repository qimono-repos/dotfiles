#!/usr/bin/env bash
# =============================================================================
# install-guix-binary.sh — install GNU Guix 1.5.0 (aarch64-linux) on Ubuntu
#
# This script must be run ONCE with sudo as a normal user (sudo prompts for
# the password). Follows the official "Installing the binary installation"
# procedure from the Guix manual for a foreign distro.
#
# Usage:
#   cd ~/source/repos/qimono-repos/dotfiles
#   sudo ./ubuntu-len-yog-ARM64/scripts/install-guix-binary.sh
#
# What it does (all idempotent):
#   1. Unpacks the verified binary tarball to /
#      (creates /gnu/store, /var/guix, guix at current-guix profile, …)
#      NOTE: this aarch64 tarball does NOT ship /usr/local/bin/guix — the
#      binary lives at /var/guix/profiles/per-user/root/current-guix/bin/guix.
#   2. Creates the guixbuild group + guixbuilder01..10 users
#   3. Makes /gnu/store world-readable
#   4. Prints next steps.
#
# THEN run finish-guix-binary.sh (same dir, sudo) to:
#   - create /usr/local/bin/guix symlink
#   - authorize the substitute signing keys
#   - install + enable the guix-daemon systemd unit
# =============================================================================
set -euo pipefail

VERSION="1.5.0"
ARCH="aarch64-linux"
TARBALL="/tmp/opencode/guix-binary-${VERSION}.${ARCH}.tar.xz"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "error: run this script with sudo (interactive password prompt)." >&2
  exit 1
fi

echo "==> GNU Guix ${VERSION} (${ARCH}) binary install"
if [[ ! -f "$TARBALL" ]]; then
  echo "error: $TARBALL not found. Download first:" >&2
  echo "  curl -L -o $TARBALL https://ftpmirror.gnu.org/gnu/guix/guix-binary-${VERSION}.${ARCH}.tar.xz" >&2
  exit 1
fi

echo
echo "[1/6] Unpacking tarball to /"
tar --warning=no-timestamp -xf "$TARBALL" -C /

echo
echo "[2/6] Creating guixbuild group + build users"
groupadd --system guixbuild 2>/dev/null || true
for i in $(seq -w 1 10); do
  useradd -g guixbuild -G guixbuild \
          -d /var/empty -s "$(command -v nologin)" \
          -c "Guix build user $i" --system \
          "guixbuilder$i" 2>/dev/null || true
done

echo
echo "[3/6] Making store world-readable"
chown -R root:root /var/guix
chown -R root:root /gnu/store
chmod -R a+rX /gnu/store
chmod 755 /gnu /gnu/store /var/guix

echo
echo "[4/6] Verify guix binary shipped in profile"
GUIX="/var/guix/profiles/per-user/root/current-guix/bin/guix"
if [[ -x "$GUIX" ]]; then
  echo "   launcher: $GUIX"
else
  echo "   error: $GUIX missing after unpack — tarball layout unexpected." >&2
  exit 1
fi

echo
echo "==========================================================="
echo " [6/6] UNPACK + USERS OK — Guix store is installed."
echo " Now finish the other half (keys + daemon + /usr/local/bin):"
echo "   sudo $ROOT/scripts/finish-guix-binary.sh"
echo "==========================================================="
