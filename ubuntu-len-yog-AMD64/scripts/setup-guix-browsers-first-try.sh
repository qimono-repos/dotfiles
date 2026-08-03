#!/usr/bin/env bash
# Graceful first-try install of Guix Epiphany + Firefox on Ubuntu.
#
#   ./scripts/setup-guix-browsers-first-try.sh           # print plan
#   ./scripts/setup-guix-browsers-first-try.sh prereqs   # sudo userns + nonguix key
#   ./scripts/setup-guix-browsers-first-try.sh install   # guix install both browsers
#   ./scripts/setup-guix-browsers-first-try.sh all       # prereqs + install + desktop links
#
# Prefer this over raw profile-full.scm the first time (smaller failure domain).
# Later, keep browsers in profile-full.scm and re-apply -m with the same URLs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUBST_URLS='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
MODE="${1:-plan}"

ensure_guix_current() {
  if [[ -d "$HOME/.config/guix/current/bin" ]]; then
    export PATH="$HOME/.config/guix/current/bin:$PATH"
  fi
  hash -r 2>/dev/null || true
  if ! command -v guix >/dev/null 2>&1; then
    echo "error: guix not found. Install Guix and run guix pull first." >&2
    exit 1
  fi
  local w
  w="$(command -v guix)"
  if [[ "$w" != *'/.config/guix/current/bin/guix' ]]; then
    echo "WARN: guix is $w"
    echo "      expected …/.config/guix/current/bin/guix (after guix pull)."
    echo "      Fix: export PATH=\"\$HOME/.config/guix/current/bin:\$PATH\" && hash guix"
    if [[ ! -x "$HOME/.config/guix/current/bin/guix" ]]; then
      echo "error: no post-pull guix; run: guix pull" >&2
      exit 1
    fi
    export PATH="$HOME/.config/guix/current/bin:$PATH"
    hash -r
  fi
  echo "using guix: $(command -v guix)"
  guix describe 2>&1 | head -12 || true
  if ! guix show firefox >/dev/null 2>&1; then
    echo "error: firefox unknown — channels/pull missing nonguix?" >&2
    echo "  ensure ~/.config/guix/channels.scm has nonguix, then: guix pull" >&2
    exit 1
  fi
}

check_disk() {
  local avail_kb
  avail_kb="$(df -Pk / | awk 'NR==2{print $4}')"
  # warn under ~25G free
  if [[ "${avail_kb:-0}" -lt 25000000 ]]; then
    echo "WARN: low free space on / (${avail_kb} KiB). Consider: guix gc -F 20G"
  else
    echo "disk free on /: ok ($(df -h / | awk 'NR==2{print $4}'))"
  fi
}

cmd_plan() {
  cat <<EOF
=== First-try Guix browsers (Epiphany + Firefox) ===
Lessons: docs/LESSONS-guix-browsers.md

0. guix pull   # channels.scm must include nonguix
1. $0 prereqs  # sudo: userns + nonguix signing key
2. $0 install  # guix install epiphany firefox (substitutes)
3. source ~/.guix-profile/etc/profile && epiphany & firefox &
4. $ROOT/scripts/link-guix-desktop-apps.sh

Substitute URLs:
  $SUBST_URLS

Later (preferred declarative):
  guix package -m $ROOT/guix/manifests/profile-full.scm \\
    --substitute-urls='$SUBST_URLS'
EOF
}

cmd_prereqs() {
  "$ROOT/scripts/setup-guix-browser-prereqs.sh"
}

cmd_install() {
  ensure_guix_current
  check_disk
  echo "==> guix install epiphany firefox (prefer substitutes, not source build)"
  echo "    If you see firefox-*.source*.drv building, Ctrl+C and re-check prereqs."
  guix install epiphany firefox --substitute-urls="$SUBST_URLS"
  export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
  "$ROOT/scripts/link-guix-desktop-apps.sh" || true
  echo
  echo "OK. Test:"
  echo "  source ~/.guix-profile/etc/profile"
  echo "  epiphany &"
  echo "  firefox &"
  command -v firefox && firefox --version || true
  command -v epiphany && epiphany --version || true
}

case "$MODE" in
  plan|help|-h|--help) cmd_plan ;;
  prereqs) cmd_prereqs ;;
  install) cmd_install ;;
  all)
    cmd_prereqs
    cmd_install
    ;;
  *)
    echo "usage: $0 [plan|prereqs|install|all]" >&2
    exit 1
    ;;
esac
