#!/usr/bin/env bash
# Install GitHub CLI from the maintained Guix package in the complete VPS profile.
set -Eeuo pipefail
GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
[[ -x "$GUIX_PROFILE/bin/gh" ]] || {
  echo "GitHub CLI is missing from the complete Guix profile. Reapply guix/manifest.scm." >&2; exit 1;
}
"$GUIX_PROFILE/bin/gh" --version | sed -n '1,2p'
echo "Installed GitHub CLI. Run 'gh auth login' interactively to authenticate."
