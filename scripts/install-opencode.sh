#!/usr/bin/env bash
# Qimono dotfiles — fleet-standard opencode CLI installer (Bun-managed).
#
# Idempotent: safe to re-run on any fleet machine; installs only when missing.
# Expected-vs-actual output in the shared status style (OK / MISS / WAIT / PLAN),
# mirroring llm/install-ollama-stack.sh.
#
# Uses `bun add -g opencode-ai` so version + upgrades stay managed by Bun
# (the same wrapper npm/bun distribute). On ARM64 (Snapdragon/Apple) Bun pulls
# the matching native aarch64 binary, so no x86_64-only blobs.
#
# Usage:
#   ./install-opencode.sh                # probe + install whatever is missing
#   ./install-opencode.sh --dry-run      # probe only, change nothing
#   ./install-opencode.sh --version X    # pin a specific version
#
# Env overrides: OPENCODE_VERSION, OPENCODE_BIN (expected binary path)
# Fleet standard (2026-08-27): bun 1.3.14, opencode latest (1.18.23 on ARM64).
# See ubuntu-len-yog-ARM64/QA/opencode.md for the QA checklist.

set -uo pipefail

OPENCODE_VERSION="${OPENCODE_VERSION:-}"
DRY_RUN=0
BUN_UNMANAGED="${HOME}/.opencode/bin/opencode"   # legacy manual-install path
# Preferred: a bun-managed hook; fall back to whatever is on $PATH.
OPENCODE_BIN="${OPENCODE_BIN:-$(command -v opencode 2>/dev/null || echo "${HOME}/.bun/bin/opencode")}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     DRY_RUN=1 ;;
    --version)     OPENCODE_VERSION="${2:?--version needs a tag}"; shift ;;
    -h|--help)     sed -n '2,21p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }
plan() { printf '  %-40s PLAN  %s\n' "$1" "$2"; }

probe() {
  PROBE_BUN=0 PROBE_BIN=0 PROBE_PIN=0 PROBE_LEGACY=0

  if command -v bun >/dev/null 2>&1; then
    PROBE_BUN=1
    ok "bun runtime" "$(command -v bun) ($(bun --version 2>&1 | head -1))"
  else
    bad "bun runtime" "not installed (install bun first)"
  fi

  if [[ -n "$OPENCODE_BIN" && -x "$OPENCODE_BIN" ]]; then
    PROBE_BIN=1
    ok "opencode binary" "$OPENCODE_BIN ($($OPENCODE_BIN --version 2>&1 | head -1))"
  elif command -v opencode >/dev/null 2>&1; then
    PROBE_BIN=1
    ok "opencode binary" "$(command -v opencode) ($(opencode --version 2>&1 | head -1))"
  elif [[ -x "$BUN_UNMANAGED" ]]; then
    # Legacy manual install (bin-folder binary, not bun-managed) → offer takeover.
    PROBE_BIN=1 PROBE_LEGACY=1
    warn "opencode binary" "$BUN_UNMANAGED — pre-bun install (not bun-managed)"
  else
    bad "opencode binary" "not installed"
  fi

  if (( PROBE_BIN )); then
    # Verified upward (>=) so bun upgrades stay effective; exact pin optional.
    if [[ -n "$OPENCODE_VERSION" ]]; then
      PROBE_PIN=1
      ok "opencode pin" "explicit OPENCODE_VERSION=${OPENCODE_VERSION} (bun owns future bumps)"
    else
      ok "opencode pin" "tracking bun's latest (unpinned)"
    fi
  fi
}

echo "=== opencode on $(hostname) — bun-managed — $(date '+%Y-%m-%d %H:%M') ==="
echo
probe

DO_INSTALL=0
# Install when absent, or when a legacy (non-bun) binary should be taken over.
[[ $PROBE_BIN == 0 ]] && [[ $PROBE_BUN == 1 ]] && DO_INSTALL=1
[[ $PROBE_LEGACY == 1 ]] && [[ $PROBE_BUN == 1 ]] && DO_INSTALL=1

if (( DO_INSTALL )); then
  cmd="bun add -g opencode-ai${OPENCODE_VERSION:+@${OPENCODE_VERSION}}"
  if (( DRY_RUN )); then
    plan "install opencode" "$cmd${PROBE_LEGACY:+" (takeover of ${BUN_UNMANAGED})"}"
  else
    echo "--- installing opencode via bun ---"
    if $cmd; then
      ok "install opencode" "done ($(command -v opencode))"
      # bun links into ~/.bun/bin; ensure it is on $PATH for this shell.
      export PATH="${HOME}/.bun/bin:$PATH"
      ok "opencode ready" "$(opencode --version 2>&1 | head -1)"
      if (( PROBE_LEGACY )); then
        # Neutralize the old manual binary so PATH resolution is unambiguous.
        mv "$BUN_UNMANAGED" "${BUN_UNMANAGED}.pre-bun" 2>/dev/null \
          && warn "legacy binary" "moved to ${BUN_UNMANAGED}.pre-bun (rollback available)"
      fi
    else
      bad "install opencode" "bun install failed"
      echo "hint: run 'curl -fsSL https://bun.sh/install | bash' first, or fix ~/.bun" >&2
      exit 1
    fi
  fi
else
  (( DRY_RUN )) || ok "nothing to do" "opencode already present"
fi

echo
echo "Verify in a new shell:  opencode upgrade      # bun-managed latest"
echo "                        opencode --version"
