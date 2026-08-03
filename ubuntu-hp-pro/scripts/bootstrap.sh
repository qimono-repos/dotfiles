#!/usr/bin/env bash
# bootstrap.sh — bare Ubuntu HP ProBook → Guix + Epiphany + Firefox
#
# Expectation: no Guix / no scientific stack yet. One session, sudo available.
# Confidence ~85–90% on x86_64 Ubuntu with free disk + network (see CONFIDENCE.md).
#
# Usage:
#   cd …/dotfiles/ubuntu-hp-pro
#   ./scripts/bootstrap.sh              # full path
#   ./scripts/bootstrap.sh --skip-snap  # keep snap browsers until you test
#   ./scripts/bootstrap.sh --from N     # resume from step N (0–6)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SKIP_SNAP=0
FROM=0
for arg in "$@"; do
  case "$arg" in
    --skip-snap) SKIP_SNAP=1 ;;
    --from=*) FROM="${arg#--from=}" ;;
    --from)
      shift || true
      ;;
    [0-9]*) FROM="$arg" ;;
    -h|--help)
      sed -n '1,25p' "$0"
      exit 0
      ;;
  esac
done

# parse --from 3 style
args=("$@")
for i in "${!args[@]}"; do
  if [[ "${args[$i]}" == "--from" && -n "${args[$((i+1))]:-}" ]]; then
    FROM="${args[$((i+1))]}"
  fi
done

log() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
die() { echo "error: $*" >&2; exit 1; }

[[ "$(uname -m)" == "x86_64" ]] || die "this bootstrap targets x86_64 (got $(uname -m))"

echo "=============================================="
echo " ubuntu-hp-pro bootstrap"
echo " root: $ROOT"
echo " host: $(hostname)  arch: $(uname -m)"
echo " goal: Guix + epiphany + firefox (substitutes)"
echo " skip snap remove: $SKIP_SNAP  from step: $FROM"
echo "=============================================="

run_step() {
  local n="$1" title="$2" script="$3"
  if [[ "$FROM" -gt "$n" ]]; then
    echo "[skip step $n] $title"
    return 0
  fi
  log "step $n: $title"
  bash "$script"
}

run_step 0 "apt minimum (curl, certs, locales)" "$ROOT/scripts/00-host-apt-min.sh"
run_step 1 "install Guix if missing"          "$ROOT/scripts/10-install-guix.sh"
run_step 2 "channels + guix pull (nonguix)"   "$ROOT/scripts/20-guix-pull-channels.sh"
run_step 3 "userns + nonguix substitute key"  "$ROOT/scripts/30-browser-prereqs.sh"
run_step 4 "guix install epiphany firefox"  "$ROOT/scripts/40-install-browsers.sh"
run_step 5 "shell PATH + desktop links"       "$ROOT/scripts/50-shell-path.sh"

if [[ "$SKIP_SNAP" -eq 0 ]]; then
  run_step 6 "remove snap firefox/epiphany"   "$ROOT/scripts/60-remove-snap-browsers.sh"
else
  echo "[skip step 6] snap removal (--skip-snap)"
fi

# Force current guix for final check
export PATH="${HOME}/.config/guix/current/bin:${PATH:-}"
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
# shellcheck disable=SC1091
[[ -r "$GUIX_PROFILE/etc/profile" ]] && source "$GUIX_PROFILE/etc/profile"

echo
echo "=============================================="
echo " BOOTSTRAP FINISHED"
echo "=============================================="
echo "Open a NEW terminal (or: source ~/.zshrc), then:"
echo "  source ~/.guix-profile/etc/profile"
echo "  which guix          # …/current/bin/guix preferred"
echo "  epiphany &"
echo "  firefox &"
echo
echo "If Epiphany traps: cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns  # must be 0"
echo "If firefox unknown: export PATH=\"\$HOME/.config/guix/current/bin:\$PATH\" && hash guix"
echo "Lessons: ../ubuntu-len-yog-AMD64/docs/LESSONS-guix-browsers.md"
echo "=============================================="

# Soft verify
if command -v firefox >/dev/null 2>&1 && command -v epiphany >/dev/null 2>&1; then
  echo "VERIFY: firefox=$(command -v firefox)  epiphany=$(command -v epiphany)"
  firefox --version 2>/dev/null || true
  epiphany --version 2>/dev/null || true
else
  echo "WARN: browsers not on PATH in this shell — open new terminal and source profile"
fi
