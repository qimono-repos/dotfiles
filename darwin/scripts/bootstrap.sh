#!/usr/bin/env bash
# bootstrap.sh — darwin pack orchestrator (macOS HOST side).
# Called by fleet/brew.sh after Xcode CLT + Homebrew + brew bundle + clone.
# Flows (all idempotent):
#   [0] macOS 26 Tahoe gate + Apple Silicon
#   [1] stow shell config (oh-my-posh catppuccin, ghostty, zsh snippets)
#   [2] install container CLI + podman + start the container runtime
#   [3] build Debian+systemd image & create the dev machine (qi-dev)
#   [4] write the Guix-in-container bootstraps into $HOME
# Finish INSIDE the machine (see output tail).
# Usage: ./scripts/bootstrap.sh [--dry-run]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) echo "usage: $0 [--dry-run]"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

ok()  { printf '  %-42s OK    %s\n' "$1" "$2"; }
bad() { printf '  %-42s MISS  %s\n' "$1" "$2"; }
warn(){ printf '  %-42s WAIT  %s\n' "$1" "$2"; }
plan(){ printf '  %-42s PLAN  %s\n' "$1" "$2"; }

echo "=== bootstrap: darwin pack (macOS host) ==="
echo " host: $(hostname) | $(uname -m)"

# ---- [0] hard gate ------------------------------------------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: darwin pack boots only on macOS (this is $(uname -s))." >&2
  exit 2
fi
if [[ "$(uname -m)" != "arm64" ]]; then
  echo "error: Apple Silicon required (found $(uname -m))." >&2
  exit 2
fi
MAJOR="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
if (( ${MAJOR:-0} < 26 )); then
  bad "macOS gate" "macOS $MAJOR < 26 (Tahoe) — update macOS first, then re-run"
  exit 2
fi
ok "macOS gate" "$(sw_vers -productVersion) on arm64"

# ---- [1] stow shell -------------------------------------------------------------
echo "--- [1/4] stow shell config ---"
if command -v stow >/dev/null 2>&1; then
  if (( DRY_RUN )); then
    plan "stow shell" "scripts/stow-apply.sh"
  else
    "$ROOT/scripts/stow-apply.sh"
  fi
else
  warn "stow" "not installed — add 'stow' to fleet/Brewfile and rerun brew bundle"
fi

# ---- [2] container CLI + podman + runtime ---------------------------------------
echo "--- [2/4] Apple Container + Podman ---"
"$ROOT/scripts/install-container.sh" ${DRY_RUN:+--dry-run}

# ---- [3] dev machine --------------------------------------------------------------
echo "--- [3/4] container machine (qi-dev) ---"
"$ROOT/scripts/container-machine-create.sh" ${DRY_RUN:+--dry-run}

# ---- [4] Guix-in-container bootstraps ---------------------------------------------
echo "--- [4/4] write Guix-in-container scripts into \$HOME ---"
if (( DRY_RUN )); then
  plan "guix-in-container" "scripts/gen-guix-in-container.sh"
else
  "$ROOT/scripts/gen-guix-in-container.sh"
fi

echo
if (( DRY_RUN )); then
  echo "dry-run complete — nothing changed."
else
  cat <<'EOF'
===== DONE (host). Finish INSIDE the machine =====
  container machine run qi-dev
  sudo bash ~/.qimono/guix-system-install.sh     # root: apt + guix-install.sh
  bash ~/.qimono/guix-user-bootstrap.sh          # user: pull + manifest
  source ~/.guix-profile/etc/profile && guix shell hello -- hello
EOF
fi