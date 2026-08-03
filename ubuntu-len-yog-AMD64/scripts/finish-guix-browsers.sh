#!/usr/bin/env bash
# finish-guix-browsers.sh — print + optionally run end-of-day browser setup.
# Steps that need YOUR password are printed clearly; agent cannot sudo.
#
#   ./scripts/finish-guix-browsers.sh          # show checklist
#   ./scripts/finish-guix-browsers.sh run      # run non-sudo parts after you did sudo

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-show}"

cat <<'EOF'
========== Guix GNOME Web + Firefox (see docs/LESSONS-guix-browsers.md) ==========

Preferred first-try orchestrator:
  ./scripts/setup-guix-browsers-first-try.sh all

A) One-time sudo — Epiphany userns + nonguix Firefox substitutes
------------------------------------------------------------
./scripts/setup-guix-browser-prereqs.sh
# or manually:
# ./scripts/install-host-sysctl.sh
# # (or: sudo sysctl -w … + tee /etc/sysctl.d/99-guix-userns.conf)
# curl -fsSL https://substitutes.nonguix.org/signing-key.pub -o /tmp/nonguix-signing-key.pub
# sudo guix archive --authorize < /tmp/nonguix-signing-key.pub

B) New shell env (post-pull guix MUST win over /usr/local/bin/guix)
------------------------------------------------------------
export PATH="$HOME/.config/guix/current/bin:$PATH"
hash guix && which guix   # …/current/bin/guix
export GUIX_PROFILE="$HOME/.guix-profile"
source "$GUIX_PROFILE/etc/profile"

C) Install browsers — first try: guix install (smaller domain)
------------------------------------------------------------
guix install epiphany firefox \
  --substitute-urls='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
# If you see firefox-*.source* building → Ctrl+C, re-run prereqs

# Later declarative full profile:
# guix package -m guix/manifests/profile-full.scm --substitute-urls='…same…'

D) Desktop icons + launch
------------------------------------------------------------
./scripts/link-guix-desktop-apps.sh
source "$HOME/.guix-profile/etc/profile"
epiphany &
firefox &

Open: epiphany = GNOME Web.  firefox = Guix Firefox.
App grid: Super key → "Web" or "Firefox" (log out/in if missing).

Do NOT compile Firefox from source if substitutes fail — fix step A key first.
============================================================
EOF

if [[ "$MODE" != "run" ]]; then
  exit 0
fi

export PATH="$HOME/.config/guix/current/bin:$PATH"
hash guix 2>/dev/null || true
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
# shellcheck disable=SC1091
source "$GUIX_PROFILE/etc/profile"

if [[ "$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns)" != "0" ]]; then
  echo "WARN: userns still restricted — run the sudo sysctl lines above" >&2
fi

echo "==> guix package -m profile-full.scm (may download Firefox ~76MiB)..."
guix package -m "$ROOT/guix/manifests/profile-full.scm" \
  --substitute-urls='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'

# shellcheck disable=SC1091
source "$GUIX_PROFILE/etc/profile"
"$ROOT/scripts/link-guix-desktop-apps.sh"
echo "Try: epiphany &   and   firefox &"
