#!/usr/bin/env bash
# Day-1 unattended path for a fresh Ubuntu VPS: prereqs → codex → opencode →
# LLM wiring → status. Run it on the VPS itself (root or sudo-capable user).
#
# Usage:
#   ./bootstrap.sh                 # full install + configure
#   ./bootstrap.sh --dry-run       # probe + print the plan, change nothing
#   ./bootstrap.sh --skip-prereqs  # you already have curl/python3/ca-certificates
#
# Any remaining flags are passed to configure-llm.sh, e.g.
#   ./bootstrap.sh --opencode-model anthropic/claude-sonnet-5-5
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DRY_RUN=0
SKIP_PREREQS=0
PASSTHRU=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)       DRY_RUN=1; PASSTHRU+=(--dry-run) ;;
    --skip-prereqs)  SKIP_PREREQS=1 ;;
    -h|--help)       sed -n '2,15p' "$0"; exit 0 ;;
    *)               PASSTHRU+=("$1") ;;
  esac
  shift
done

echo "=== vps-ubuntu bootstrap ==="
echo "    1 apt prereqs (curl, ca-certificates, python3, tar)"
echo "    2 codex CLI (standalone installer)"
echo "    3 opencode CLI (curl installer)"
echo "    4 LLM provider wiring"
echo "    5 status"
echo

as_root() {
  if [[ $EUID -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "error: need root or sudo for: $*" >&2
    return 1
  fi
}

# ---- 1. prereqs ------------------------------------------------------------
if (( ! SKIP_PREREQS )); then
  MISSING=()
  for c in curl tar python3; do
    command -v "$c" >/dev/null 2>&1 || MISSING+=("$c")
  done
  if (( ${#MISSING[@]} )); then
    echo "--- installing apt prereqs: ${MISSING[*]} ---"
    if (( DRY_RUN )); then
      echo "  PLAN  apt-get update && apt-get install -y ca-certificates curl python3 tar"
    else
      as_root apt-get update
      as_root apt-get install -y ca-certificates curl python3 tar
    fi
  else
    echo "--- prereqs present: curl tar python3 ---"
  fi
fi

# ---- 2-4. install + configure ---------------------------------------------
DRY_FLAG=()
(( DRY_RUN )) && DRY_FLAG+=(--dry-run)
"$ROOT/scripts/install-codex.sh" "${DRY_FLAG[@]}"
"$ROOT/scripts/install-opencode.sh" "${DRY_FLAG[@]}"
"$ROOT/scripts/configure-llm.sh" "${PASSTHRU[@]}"

# ---- 5. status -------------------------------------------------------------
echo
"$ROOT/scripts/status.sh"

echo
echo "=== bootstrap done ==="
echo "Edit ${XDG_CONFIG_HOME:-$HOME/.config}/qimono/providers.env, re-run"
echo "  $ROOT/scripts/configure-llm.sh"
echo "then open a new shell and run: codex | opencode"
