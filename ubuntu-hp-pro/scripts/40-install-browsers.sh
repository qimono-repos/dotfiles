#!/usr/bin/env bash
# Install Guix epiphany + firefox via substitutes (not source build).
# Hard gates: post-pull guix, disk free, guix weather for firefox on nonguix.
set -euo pipefail

SUBST_URLS='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
NONGUIX_URL='https://substitutes.nonguix.org'
# ~40 GiB free recommended for pull residue + browser closures + headroom
MIN_FREE_KB=$((40 * 1024 * 1024))

export PATH="${HOME}/.config/guix/current/bin:/usr/local/bin:${PATH:-}"
hash -r 2>/dev/null || true

if ! command -v guix >/dev/null 2>&1; then
  echo "error: guix missing" >&2
  exit 1
fi

# Prefer post-pull guix if present but not first on PATH
if [[ "$(command -v guix)" != *'/.config/guix/current/bin/guix' ]]; then
  if [[ -x "$HOME/.config/guix/current/bin/guix" ]]; then
    export PATH="$HOME/.config/guix/current/bin:$PATH"
    hash -r
  fi
fi

echo "using guix: $(command -v guix)"
if [[ "$(command -v guix)" != *'/.config/guix/current/bin/guix' ]]; then
  echo "error: must use post-pull guix at ~/.config/guix/current/bin/guix" >&2
  echo "       got: $(command -v guix)" >&2
  echo "       run: ./scripts/20-guix-pull-channels.sh" >&2
  exit 1
fi

if ! guix show firefox >/dev/null 2>&1; then
  echo "error: firefox unknown — run 20-guix-pull-channels.sh first" >&2
  exit 1
fi

avail_kb="$(df -Pk / | awk 'NR==2{print $4}')"
echo "disk free on /: $((avail_kb / 1024 / 1024)) GiB (need ≥40 GiB)"
if [[ "${avail_kb:-0}" -lt "$MIN_FREE_KB" ]]; then
  echo "error: under ~40G free on / — free space before installing browsers" >&2
  echo "       df -h /" >&2
  exit 1
fi

echo "==> guix weather firefox (must have substitutes on nonguix — do NOT compile)"
weather_log="$(mktemp)"
# shellcheck disable=SC2064
trap 'rm -f "$weather_log"' EXIT
if ! guix weather firefox --substitute-urls="$NONGUIX_URL" 2>&1 | tee "$weather_log"; then
  echo "error: guix weather failed (network / guix?). Retry when online." >&2
  exit 1
fi

# Expect a line like: "100.0% substitutes available (1 out of 1)"
if grep -qE '0\.0% substitutes available' "$weather_log"; then
  echo "error: 0% Firefox substitutes on $NONGUIX_URL" >&2
  echo "       Do NOT install (would compile for hours / fill disk)." >&2
  echo "       Retry later, or check nonguix key authorization." >&2
  exit 1
fi
if ! grep -qE '[1-9][0-9]*(\.[0-9]+)?% substitutes available' "$weather_log"; then
  # No percentage line found — be strict rather than risk source build
  if grep -qiE 'substitutes available \(0 out of' "$weather_log"; then
    echo "error: no Firefox substitutes reported" >&2
    exit 1
  fi
  echo "WARN: could not parse weather % line; continuing carefully…"
fi

echo "==> guix install epiphany firefox"
echo "    substitutes: $SUBST_URLS"
echo "    If the log starts *building* firefox-*.source* — Ctrl+C immediately."

# No --fallback: if a substitute fetch fails mid-way, fail rather than silent source build
# (Guix still builds from source when no substitute exists — weather gate above is the main protection.)
guix install epiphany firefox --substitute-urls="$SUBST_URLS"

export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
# shellcheck disable=SC1091
source "$GUIX_PROFILE/etc/profile"

echo "installed:"
guix package -I | grep -iE 'firefox|epiphany' || true
command -v firefox && firefox --version || true
command -v epiphany && epiphany --version || true
echo "OK: browsers installed"
