#!/usr/bin/env bash
# Apply the full Guix user profile. This REPLACES the previous generation.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${ROOT}/guix/manifests/profile-full.scm"

if ! command -v guix >/dev/null 2>&1; then
  echo "error: guix not found" >&2
  exit 1
fi

echo "==> guix package -m $MANIFEST"
echo "    This replaces ~/.guix-profile to match the file EXACTLY."
guix package -m "$MANIFEST"

export GUIX_PROFILE="${HOME}/.guix-profile"
# Guix profile uses ${VAR:+:} $VAR; nounset (set -u) dies on first unset VAR.
set +u
# shellcheck disable=SC1091
source "$GUIX_PROFILE/etc/profile"
set -u

echo
echo "OK: profile applied"
command -v python3 && python3 --version || true
command -v uv && uv --version || true
command -v jupyter && jupyter --version 2>/dev/null | head -5 || true
command -v stow && stow --version | head -1 || true
echo
echo "Rollback if needed:  guix package --roll-back"
