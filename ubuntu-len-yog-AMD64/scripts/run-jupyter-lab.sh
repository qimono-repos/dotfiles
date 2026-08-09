#!/usr/bin/env bash
# Start Guix Jupyter Notebook using stowed config (127.0.0.1:5005).
# Name kept for existing docs; this is classic `jupyter notebook`, not Lab.
set -euo pipefail

export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
fi

if ! command -v jupyter >/dev/null 2>&1; then
  echo "error: jupyter not on PATH. Install with: guix install jupyter" >&2
  echo "       (then source ~/.guix-profile/etc/profile)" >&2
  exit 1
fi

WS="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"
if [[ -d "$WS" ]]; then
  cd "$WS"
else
  echo "warn: quantum workspace not found at $WS; starting in \$HOME" >&2
  cd "$HOME"
fi

# ip/port/open_browser from ~/.jupyter/jupyter_notebook_config.py (stow package jupyter)
exec jupyter notebook
