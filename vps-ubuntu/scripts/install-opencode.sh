#!/usr/bin/env bash
# Qimono vps-ubuntu — install the opencode CLI over curl.
#
# Uses the official installer instead of Bun/npm, which is what a bare VPS
# wants. Lands in $HOME/.opencode/bin/opencode. Idempotent: only installs when
# `opencode` is missing (or when --force is passed); re-run with --force to
# upgrade in place.
#
# Usage:
#   ./install-opencode.sh
#   ./install-opencode.sh --dry-run
#   ./install-opencode.sh --force
#   ./install-opencode.sh --version 1.18.23
#
# Env overrides: OPENCODE_VERSION, OPENCODE_INSTALL_DIR
# Upstream: https://github.com/anomalyco/opencode  (installer: opencode.ai/install)

set -uo pipefail

OPENCODE_VERSION="${OPENCODE_VERSION:-}"
OPENCODE_INSTALL_DIR="${OPENCODE_INSTALL_DIR:-$HOME/.opencode/bin}"
INSTALL_URL="https://opencode.ai/install"
DRY_RUN=0
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --force)   FORCE=1 ;;
    --version) OPENCODE_VERSION="${2:?--version needs a tag}"; shift ;;
    -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }
plan() { printf '  %-40s PLAN  %s\n' "$1" "$2"; }

opencode_bin() {
  if command -v opencode >/dev/null 2>&1; then
    command -v opencode
  elif [[ -x "${OPENCODE_INSTALL_DIR}/opencode" ]]; then
    printf '%s\n' "${OPENCODE_INSTALL_DIR}/opencode"
  fi
}

probe() {
  PROBE_BIN=0
  BIN="$(opencode_bin)"
  if [[ -n "$BIN" ]]; then
    PROBE_BIN=1
    ok "opencode binary" "$BIN ($("$BIN" --version 2>&1 | head -1))"
  else
    bad "opencode binary" "not installed"
  fi
}

echo "=== opencode on $(hostname) — curl installer — $(date '+%Y-%m-%d %H:%M') ==="
echo
probe

DO_INSTALL=0
[[ $PROBE_BIN == 0 ]] && DO_INSTALL=1
[[ $FORCE == 1 ]] && DO_INSTALL=1

if (( ! DO_INSTALL )); then
  (( DRY_RUN )) || ok "nothing to do" "opencode already present"
  echo
  echo "Install dir: ${OPENCODE_INSTALL_DIR}"
  exit 0
fi

if (( DRY_RUN )); then
  plan "install opencode" "download ${INSTALL_URL} and run it"
  [[ -n "$OPENCODE_VERSION" ]] && plan "pin version" "$OPENCODE_VERSION"
  exit 0
fi

command -v curl >/dev/null 2>&1 || { bad "curl" "required"; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "--- downloading opencode installer ---"
if ! curl -fsSL "$INSTALL_URL" -o "${TMP}/install.sh"; then
  bad "download installer" "$INSTALL_URL"
  exit 1
fi
ok "download installer" "$(wc -c <"${TMP}/install.sh" | tr -d ' ') bytes"

# --no-modify-path: keep shell edits deterministic and owned by
# configure-llm.sh (which writes one guarded PATH + env block).
ARGS=(--no-modify-path)
[[ -n "$OPENCODE_VERSION" ]] && ARGS+=(--version "$OPENCODE_VERSION")

echo "--- installing opencode into ${OPENCODE_INSTALL_DIR} ---"
if bash "${TMP}/install.sh" "${ARGS[@]}"; then
  ok "install opencode" "done"
else
  bad "install opencode" "installer failed"
  exit 1
fi

export PATH="${OPENCODE_INSTALL_DIR}:${PATH}"
echo
echo "--- re-probe after install ---"
echo
probe

if [[ -n "$(opencode_bin)" ]]; then
  echo
  echo "Run:            opencode"
  echo "Non-interactive: opencode run \"explain this repo\""
  echo "Provider setup:  $(dirname "${BASH_SOURCE[0]}")/configure-llm.sh"
fi
