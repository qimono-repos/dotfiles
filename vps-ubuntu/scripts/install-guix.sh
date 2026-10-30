#!/usr/bin/env bash
# Install GNU Guix on a foreign Ubuntu system using the official installer.
set -Eeuo pipefail
[[ ${EUID} -eq 0 ]] || { echo "Run as root: sudo $0" >&2; exit 1; }

if command -v guix >/dev/null 2>&1 && [[ -x /var/guix/profiles/per-user/root/current-guix/bin/guix || -x /usr/local/bin/guix ]]; then
  echo "GNU Guix already installed: $(guix --version | head -1)"
  exit 0
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y bash ca-certificates curl gnupg tar xz-utils wget uidmap

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
installer="$tmp/guix-install.sh"
echo "Downloading official GNU Guix installer..."
curl --fail --location --retry 3 --retry-delay 2 https://guix.gnu.org/guix-install.sh -o "$installer"
bash -n "$installer"
chmod 700 "$installer"
echo "Running official installer. Follow its confirmation prompt if shown."
bash "$installer"

if ! command -v guix >/dev/null 2>&1; then
  for candidate in /var/guix/profiles/per-user/root/current-guix/bin/guix /usr/local/bin/guix; do
    if [[ -x "$candidate" ]]; then export PATH="$(dirname "$candidate"):$PATH"; break; fi
  done
fi
command -v guix >/dev/null 2>&1 || { echo "Guix installer completed but guix is not on PATH." >&2; exit 1; }
guix --version
systemctl is-active --quiet guix-daemon && echo "guix-daemon: active" || {
  systemctl enable --now guix-daemon 2>/dev/null || true
  systemctl is-active guix-daemon || true
}
