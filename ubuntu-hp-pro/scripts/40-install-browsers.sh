#!/usr/bin/env bash
# Install Guix epiphany + firefox via substitutes (not source build).
set -euo pipefail

SUBST_URLS='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'

export PATH="${HOME}/.config/guix/current/bin:/usr/local/bin:${PATH:-}"
hash -r 2>/dev/null || true

if ! command -v guix >/dev/null 2>&1; then
  echo "error: guix missing" >&2
  exit 1
fi

which guix
if [[ "$(command -v guix)" != *'/.config/guix/current/bin/guix' ]]; then
  echo "WARN: not using post-pull guix ($(command -v guix))"
  if [[ -x "$HOME/.config/guix/current/bin/guix" ]]; then
    export PATH="$HOME/.config/guix/current/bin:$PATH"
    hash -r
  fi
fi

if ! guix show firefox >/dev/null 2>&1; then
  echo "error: firefox unknown — run 20-guix-pull-channels.sh first" >&2
  exit 1
fi

avail_kb="$(df -Pk / | awk 'NR==2{print $4}')"
if [[ "${avail_kb:-0}" -lt 15000000 ]]; then
  echo "WARN: under ~15G free on / — consider freeing space first"
fi

echo "==> guix install epiphany firefox"
echo "    substitutes: $SUBST_URLS"
echo "    If the log starts *building* firefox-*.source* — Ctrl+C and fix nonguix key/URLs."

guix install epiphany firefox --substitute-urls="$SUBST_URLS"

export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
# shellcheck disable=SC1091
source "$GUIX_PROFILE/etc/profile"

echo "installed:"
guix package -I | grep -iE 'firefox|epiphany' || true
command -v firefox && firefox --version || true
command -v epiphany && epiphany --version || true
echo "OK: browsers installed"
