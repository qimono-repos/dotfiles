#!/usr/bin/env bash
# Qimono dotfiles — fleet-standard offline LLM stack (Ollama + Gemma).
#
# Idempotent: safe to re-run on any fleet machine; never re-downloads what is
# already present. Expected-vs-actual output in the ubuntu-mini-pc status.sh
# style (OK / MISS / WAIT / PLAN).
#
# Usage:
#   ./install-ollama-stack.sh                # probe + install whatever is missing
#   ./install-ollama-stack.sh --dry-run      # probe only, change nothing
#   ./install-ollama-stack.sh --smoke        # also run a one-shot prompt test
#   ./install-ollama-stack.sh --model gemma4:e4b
#
# Env overrides: OLLAMA_MODEL, MIN_AVAIL_GB, MIN_DISK_GB
# Fleet standard (2026-08-21): OLLAMA_MODEL=gemma4:e2b — see llm/docs/local-llm.md

set -uo pipefail

OLLAMA_MODEL="${OLLAMA_MODEL:-gemma4:e2b}"
MIN_AVAIL_MB="${MIN_AVAIL_MB:-3072}"   # ~3 GiB available RAM wanted while model is resident
MIN_DISK_GB="${MIN_DISK_GB:-10}"       # headroom wanted before pulling weights
DRY_RUN=0
SMOKE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --smoke)   SMOKE=1 ;;
    --model)   OLLAMA_MODEL="${2:?--model needs a tag}"; shift ;;
    -h|--help) sed -n '2,17p' "$0"; exit 0 ;;
    *) echo "unknown arg: $1 (try --help)" >&2; exit 2 ;;
  esac
  shift
done

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }
plan() { printf '  %-40s PLAN  %s\n' "$1" "$2"; }

have_systemd() { command -v systemctl >/dev/null 2>&1 && [[ -d /run/systemd/system ]]; }

probe() {
  PROBE_BIN=0 PROBE_SVC="" PROBE_UNIT=0 PROBE_MODEL=0

  if command -v ollama >/dev/null 2>&1; then
    PROBE_BIN=1
    ok "ollama binary" "$(command -v ollama) ($(ollama --version 2>&1 | head -1))"
  else
    PROBE_BIN=0
    bad "ollama binary" "not installed"
  fi

  if have_systemd; then
    systemctl is-active ollama.service >/dev/null 2>&1
    case $? in
      0) PROBE_UNIT=1; PROBE_SVC="active"
         ok "ollama.service" "active (enabled at boot: $(systemctl is-enabled ollama.service 2>/dev/null || echo '?'))" ;;
      3) PROBE_UNIT=1; PROBE_SVC="inactive"
         warn "ollama.service" "unit present but inactive" ;;
      *) PROBE_UNIT=0
         bad "ollama.service" "no unit file" ;;
    esac
  else
    warn "ollama.service" "no systemd on this host; manage ollama manually"
  fi

  if [[ $PROBE_BIN == 1 ]]; then
    if ollama list 2>/dev/null | awk '{print $1}' | grep -qx -- "${OLLAMA_MODEL}"; then
      PROBE_MODEL=1
      ok "model ${OLLAMA_MODEL}" "pulled"
    else
      PROBE_MODEL=0
      bad "model ${OLLAMA_MODEL}" "not pulled yet"
    fi
  fi

  AVAIL_MB="$(free -m 2>/dev/null | awk '/^Mem:/{print $7}')"
  DISK_GB="$(df -BG --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')"
  if [[ -n "$AVAIL_MB" ]] && (( AVAIL_MB < MIN_AVAIL_MB )); then
    warn "available RAM" "${AVAIL_MB} MiB (< ${MIN_AVAIL_MB}) — close heavy apps before loading"
  else
    ok "available RAM" "${AVAIL_MB:-?} MiB"
  fi
  if [[ -n "$DISK_GB" ]] && (( DISK_GB < MIN_DISK_GB )); then
    bad "disk headroom on /" "${DISK_GB} G (< ${MIN_DISK_GB} G) — refusing to pull"
  else
    ok "disk headroom on /" "${DISK_GB:-?} G"
  fi
}

echo "=== qimono llm stack on $(hostname) — standard model: ${OLLAMA_MODEL} ==="
echo
probe

DO_INSTALL=0; DO_ENABLE=0; DO_PULL=0
[[ $PROBE_BIN == 0 ]]                 && DO_INSTALL=1
[[ $PROBE_UNIT == 0 ]] && have_systemd && DO_ENABLE=1
[[ $PROBE_MODEL == 0 && $PROBE_BIN == 1 ]] && { (( DISK_GB >= MIN_DISK_GB )) && DO_PULL=1; }

echo
if (( DRY_RUN )); then
  echo "--- dry run: planned actions ---"
  (( DO_INSTALL )) && plan "install ollama" "curl -fsSL https://ollama.com/install.sh | sh"
  (( DO_ENABLE ))  && plan "enable service" "sudo systemctl enable --now ollama"
  (( DO_PULL ))    && plan "pull model"     "ollama pull ${OLLAMA_MODEL}"
  (( ! DO_INSTALL && ! DO_ENABLE && ! DO_PULL )) && plan "nothing to do" "stack already complete"
else
  FAILED=0

  if (( DO_INSTALL )); then
    echo "--- installing ollama (official installer) ---"
    if curl -fsSL https://ollama.com/install.sh | sh; then
      ok "install ollama" "done"
    else
      bad "install ollama" "installer failed"; FAILED=1
    fi
  fi

  if (( DO_ENABLE )) && (( ! FAILED )); then
    echo "--- enabling ollama.service ---"
    if sudo -n systemctl enable --now ollama.service >/dev/null 2>&1 \
       || sudo systemctl enable --now ollama.service; then
      ok "enable service" "enabled + started"
    else
      warn "enable service" "could not enable (run manually: sudo systemctl enable --now ollama)"
    fi
  fi

  if (( DO_PULL )) && (( ! FAILED )); then
    echo "--- pulling ${OLLAMA_MODEL} (this can take a while) ---"
    if ollama pull "${OLLAMA_MODEL}"; then
      ok "pull ${OLLAMA_MODEL}" "done"
    else
      bad "pull ${OLLAMA_MODEL}" "failed"; FAILED=1
    fi
  fi

  if (( SMOKE )) && (( ! FAILED )); then
    echo "--- smoke test ---"
    HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -x "${HERE}/hello-llm.sh" ]]; then
      OLLAMA_MODEL="$OLLAMA_MODEL" "${HERE}/hello-llm.sh" || FAILED=1
    else
      warn "smoke test" "hello-llm.sh not found next to this script"
    fi
  fi

  echo
  echo "--- re-probe after actions ---"
  echo
  probe

  if ollama show "${OLLAMA_MODEL}" >/dev/null 2>&1; then
    echo
    echo "Run it:            ollama run ${OLLAMA_MODEL}"
    echo "Free RAM after:    ollama stop ${OLLAMA_MODEL}"
  fi
  (( FAILED )) && exit 1
fi
