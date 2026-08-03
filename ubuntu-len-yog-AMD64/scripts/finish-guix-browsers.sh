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
========== CALL IT A DAY: Guix GNOME Web + Firefox ==========

A) One-time sudo (copy-paste block) — fix Epiphany bwrap + trust nonguix substitutes
------------------------------------------------------------
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
echo 'kernel.apparmor_restrict_unprivileged_userns=0' | sudo tee /etc/sysctl.d/99-guix-userns.conf

curl -fsSL https://substitutes.nonguix.org/signing-key.pub -o /tmp/nonguix-signing-key.pub
sudo guix archive --authorize < /tmp/nonguix-signing-key.pub

B) New shell env (or: source ~/.zshrc after stow)
------------------------------------------------------------
export PATH="$HOME/.config/guix/current/bin:$PATH"
hash guix
export GUIX_PROFILE="$HOME/.guix-profile"
source "$GUIX_PROFILE/etc/profile"

C) Preferred: full profile including firefox + epiphany
------------------------------------------------------------
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64
guix package -m guix/manifests/profile-full.scm \
  --substitute-urls='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'

# OR last-resort add only firefox:
# guix install firefox --substitute-urls='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'

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
