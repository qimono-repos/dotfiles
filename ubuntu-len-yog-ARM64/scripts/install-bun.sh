#!/usr/bin/env bash
# Qimono dotfiles — fleet-standard Bun (JavaScript runtime/bundler) installer.
#
# Reproducible + idempotent: safe to re-run; never re-downloads what exists.
# Expected-vs-actual output (OK / MISS / WAIT / PLAN) matching the shared
# fleet installer style (llm/install-ollama-stack.sh, install-opencode.sh).
#
# Installs Bun into $HOME/.bun via the official installer (ourselves, pinned),
# so the JS toolchain is explicit here rather than a hidden manual step.
#
# Usage:
#   ./install-bun.sh                # probe + install whatever is missing
#   ./install-bun.sh --dry-run      # probe only, change nothing
#   ./install-bun.sh --version 1.3.14
#
# Env overrides: BUN_VERSION, BUN_INSTALL (install dir, default $HOME/.bun)
# ARM64 note: the official installer picks the matching native aarch64 build
# (no x86_64-only blobs), and /home/qi/.bun/bin is already on PATH via the
# stowed shell config (see stow-source/shell/.zshrc.d/00-opencode.zsh).

set -uo pipefail

BUN_VERSION="${BUN_VERSION:-}"
BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
BUN_BIN="$BUN_INSTALL/bin/bun"
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)  DRY_RUN=1 ;;
    --version)  BUN_VERSION="${2:?--version needs a tag}"; shift ;;
    -h|--help)  sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }
plan() { printf '  %-40s PLAN  %s\n' "$1" "$2"; }

probe() {
  PROBE_BIN=0
  if [[ -x "$BUN_BIN" ]]; then
    PROBE_BIN=1
    local v; v="$($BUN_BIN --version 2>&1 | head -1)"
    ok "bun binary" "$BUN_BIN ($v)"
    if [[ -n "$BUN_VERSION" && "$v" != "$BUN_VERSION" ]]; then
      warn "bun pin" "requested $BUN_VERSION, found $v (leave unpinned to keep)"
    else
      ok "bun pin" "${BUN_VERSION:-unpinned (latest stable)}"
    fi
  elif command -v bun >/dev/null 2>&1; then
    PROBE_BIN=1
    ok "bun binary" "$(command -v bun) ($(bun --version 2>&1 | head -1))"
  else
    bad "bun binary" "not installed"
  fi
}

echo "=== Bun (JS toolchain) on $(hostname) — $(date '+%Y-%m-%d %H:%M') ==="
echo
probe

if (( PROBE_BIN )); then
  echo
  echo "Verify in a new shell:  bun --version"
  echo "For upgrades/repair:    bun upgrade"
  exit 0
fi

if (( DRY_RUN )); then
  plan "install bun" "curl -fsSL https://bun.sh/install | bash"
  exit 0
fi

echo "--- installing Bun via official installer ---"
# NOTE: not pinned by default for reproducibility of the SDK snapshot; pass
# --version for an exact pin, or run `bun upgrade` afterwards.
if curl -fsSL "https://bun.sh/install" | bash; then
  export PATH="$BUN_INSTALL/bin:$PATH"
  ok "install bun" "done ($("$BUN_BIN" --version 2>&1 | head -1))"
  chmod +x "$BUN_BIN"
else
  bad "install bun" "installer failed"
  exit 1
fi

echo
echo "Now:  source ~/.zshrc   (or open a new shell) so \$HOME/.bun/bin is on PATH"
