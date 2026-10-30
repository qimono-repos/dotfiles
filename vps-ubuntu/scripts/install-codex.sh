#!/usr/bin/env bash
# Qimono vps-ubuntu — install the standalone OpenAI Codex CLI over curl.
#
# No npm, no Homebrew: uses the official standalone installer, which lands in
# $HOME/.local/bin/codex. Idempotent: re-running only installs when `codex` is
# missing (or when --force is passed); the upstream installer is also safe to
# re-run for upgrades.
#
# Usage:
#   ./install-codex.sh
#   ./install-codex.sh --dry-run
#   ./install-codex.sh --force
#   ./install-codex.sh --version 0.166.0
#
# Env overrides: CODEX_VERSION, CODEX_INSTALL_DIR, CODEX_INSTALLER_USE_RELEASES_OPENAI_COM
# Upstream: https://github.com/openai/codex  (installer: chatgpt.com/codex/install.sh)

set -uo pipefail

CODEX_VERSION="${CODEX_VERSION:-}"
CODEX_INSTALL_DIR="${CODEX_INSTALL_DIR:-$HOME/.local/bin}"
PRIMARY_URL="https://chatgpt.com/codex/install.sh"
FALLBACK_URL="https://github.com/openai/codex/releases/latest/download/install.sh"
DRY_RUN=0
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    --version) CODEX_VERSION="${2:?--version needs a tag}"; shift ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }
plan() { printf '  %-40s PLAN  %s\n' "$1" "$2"; }

codex_bin() {
  if command -v codex >/dev/null 2>&1; then
    command -v codex
  elif [[ -x "${CODEX_INSTALL_DIR}/codex" ]]; then
    printf '%s\n' "${CODEX_INSTALL_DIR}/codex"
  fi
}

probe() {
  PROBE_BIN=0
  BIN="$(codex_bin)"
  if [[ -n "$BIN" ]]; then
    PROBE_BIN=1
    ok "codex binary" "$BIN ($("$BIN" --version 2>&1 | head -1))"
  else
    bad "codex binary" "not installed"
  fi
}

echo "=== codex on $(hostname) — standalone installer — $(date '+%Y-%m-%d %H:%M') ==="
echo
probe

DO_INSTALL=0
[[ $PROBE_BIN == 0 ]] && DO_INSTALL=1
[[ $FORCE == 1 ]] && DO_INSTALL=1

if (( ! DO_INSTALL )); then
  (( DRY_RUN )) || ok "nothing to do" "codex already present"
  echo
  echo "Install dir: ${CODEX_INSTALL_DIR}"
  exit 0
fi

if (( DRY_RUN )); then
  plan "install codex" "download ${PRIMARY_URL} and run it"
  [[ -n "$CODEX_VERSION" ]] && plan "pin version" "$CODEX_VERSION"
  exit 0
fi

command -v curl >/dev/null 2>&1 || { bad "curl" "required"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "--- downloading Codex installer ---"
if ! curl -fsSL "$PRIMARY_URL" -o "${TMP}/install.sh" 2>/dev/null; then
  warn "primary installer" "chatgpt.com unavailable; trying GitHub releases"
  if ! curl -fsSL "$FALLBACK_URL" -o "${TMP}/install.sh"; then
    bad "download installer" "$PRIMARY_URL"
    exit 1
  fi
fi
ok "download installer" "$(wc -c <"${TMP}/install.sh" | tr -d ' ') bytes"

echo "--- installing Codex into ${CODEX_INSTALL_DIR} ---"
INSTALL_ENV=(CODEX_NON_INTERACTIVE=1 CODEX_INSTALL_DIR="$CODEX_INSTALL_DIR")
[[ -n "$CODEX_VERSION" ]] && INSTALL_ENV+=(CODEX_RELEASE="$CODEX_VERSION")
if env "${INSTALL_ENV[@]}" sh "${TMP}/install.sh"; then
  ok "install codex" "done"
else
  bad "install codex" "installer failed"
  exit 1
fi

# The installer appends ~/.local/bin to shell profiles; make it live for this
# shell too so a following configure/status step sees the binary.
export PATH="${CODEX_INSTALL_DIR}:${PATH}"
echo
echo "--- re-probe after install ---"
echo
probe

BIN="$(codex_bin)"
if [[ -n "$BIN" ]]; then
  echo
  echo "Run:            codex"
  echo "Non-interactive: codex exec \"explain this repo\""
  echo "Login (API key): export OPENAI_API_KEY=...  (or run: codex login --api-key)"
  echo "Provider setup:  $(dirname "${BASH_SOURCE[0]}")/configure-llm.sh"
fi
