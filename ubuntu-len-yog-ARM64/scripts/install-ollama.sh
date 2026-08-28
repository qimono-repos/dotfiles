#!/usr/bin/env bash
# Fleet-standard Ollama + gemma4:e2b stack for ubuntu-len-yog-ARM64.
#
# Thin, machine-pack-local wrapper around the shared fleet installer at
#   ../../llm/install-ollama-stack.sh
# which: installs Ollama, enables ollama.service at boot, pulls gemma4:e2b,
# and (with --smoke) runs a one-shot localhost API smoke test.
#
# NOTE: install + service-enable need sudo (the shared script prompts once).
# The fully-privileged run is documented as the one step a human must watch
# (curl|sh + systemctl enable). Non-interactive probe: --dry-run.
#
# Usage:
#   ./install-ollama.sh --dry-run   # probe only, no changes (no sudo)
#   ./install-ollama.sh             # probe + install/enable/pull (may ask sudo)
#   ./install-ollama.sh --smoke     # also run the localhost smoke test

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED="$HERE/../../llm/install-ollama-stack.sh"

if [[ ! -x "$SHARED" ]]; then
  echo "error: shared fleet installer missing: $SHARED" >&2
  exit 1
fi

export OLLAMA_MODEL="${OLLAMA_MODEL:-gemma4:e2b}"
exec "$SHARED" "$@"
