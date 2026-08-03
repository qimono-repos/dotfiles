#!/usr/bin/env bash
# Install Guix-first Python toolchain: python, uv, stow (+ base manifest).
# Package manager rank: 1=guix
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT}/guix/manifests/base.scm"

if ! command -v guix >/dev/null 2>&1; then
  echo "error: guix not found. Run install-guix-ready.sh from qimono-repos first." >&2
  exit 1
fi

echo "==> Guix: applying base manifest"
echo "    $MANIFEST"
guix package -m "$MANIFEST"

# Make packages visible in this script session
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
# shellcheck disable=SC1091
source "$GUIX_PROFILE/etc/profile"

echo "==> Versions"
command -v python3 && python3 --version || true
command -v uv && uv --version || true
command -v stow && stow --version | head -1 || true

echo
echo "OK: Guix python/uv/stow installed into user profile."
echo "    If a new login shell still misses them, apply stow shell hooks:"
echo "    $ROOT/scripts/stow-apply.sh"
