#!/usr/bin/env bash
# install-container.sh — install/start Apple Container + Podman on macOS host.
# Idempotent; safe to re-run. No sudo (brew + current-user container runtime).
# macOS 26 Tahoe+ is a HARD gate — refuses to proceed on earlier OS.
#
# Usage: ./install-container.sh [--dry-run]
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

echo "=== [darwin] Apple Container + Podman host install ==="

# ---- hard gate: macOS 26 Tahoe + Apple Silicon -----------------------------
if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: this script runs on macOS (this is $(uname -s))." >&2
  exit 2
fi
if [[ "$(uname -m)" != "arm64" ]]; then
  echo "error: Apple Container requires Apple Silicon (found $(uname -m))." >&2
  exit 2
fi
MAJOR="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
if (( ${MAJOR:-0} < 26 )); then
  echo "error: macOS $MAJOR < 26 (Tahoe). Apple Container is unsupported here." >&2
  echo "       Update macOS first (Settings > General > Software Update)." >&2
  exit 2
fi
ok "macOS gate" "$(sw_vers -productVersion) on $(uname -m)"

# ---- brew must exist --------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  bad "brew" "not installed — run fleet/brew.sh first"
  exit 2
fi
ok "brew" "$(brew --version 2>/dev/null | head -1 | sed 's/^Homebrew //')"

# ---- Apple Container CLI -----------------------------------------------------
CONTAINER_OK=0
if command -v container >/dev/null 2>&1; then
  CONTAINER_OK=1
  ok "container CLI" "$(container --version 2>/dev/null | head -1)"
elif [[ -x /opt/homebrew/bin/container ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
  CONTAINER_OK=1
  ok "container CLI" "$(container --version 2>/dev/null | head -1)"
fi

if (( ! CONTAINER_OK )); then
  if (( DRY_RUN )); then
    plan "install container CLI" "brew install container"
    plan "pkg fallback"         "download signed .pkg from github.com/apple/container Releases"
  else
    echo "==> brew install container (formula exists; see docs/apple-container.md [OPEN])"
    if brew install container; then
      CONTAINER_OK=1
    else
      warn "container" "brew formula failed — download the signed .pkg from"
      warn "container" "github.com/apple/container Releases and run it, then re-run this script."
    fi
  fi
fi

# ---- Podman (parity/fallback) ------------------------------------------------
PODMAN_OK=0
if command -v podman >/dev/null 2>&1; then
  PODMAN_OK=1
  ok "podman" "$(podman --version 2>/dev/null | head -1)"
elif (( ! DRY_RUN )); then
  echo "==> brew install podman"
  if brew install podman; then
    PODMAN_OK=1
    ok "podman" "$(podman --version 2>/dev/null | head -1)"
  else
    warn "podman" "install failed — check 'brew info podman'"
  fi
else
  plan "install podman" "brew install podman"
fi

# ---- start the container runtime (first run installs a Linux kernel) --------
if (( ! CONTAINER_OK )); then
  echo
  echo "Install the container CLI first, then re-run. Nothing was started."
  exit 0
fi

STATUS="$(container system status 2>/dev/null || echo '')"
case "$STATUS" in
  *running*|*Running*|*enabled*)
    ok "container system" "running ($(echo "$STATUS" | head -1))" ;;
  *)
    if (( DRY_RUN )); then
      plan "container system start" "one-time Linux kernel install prompt (interactive)"
    else
      echo "==> container system start (first run prompts to install a Linux kernel)"
      container system start || warn "container system" "start returned non-zero — run 'container system start' manually"
      ok "container system" "start requested"
    fi
    ;;
esac

echo
echo "Done. Next: ./scripts/bootstrap.sh continues, or create the dev machine with"
echo "  ./scripts/container-machine-create.sh"