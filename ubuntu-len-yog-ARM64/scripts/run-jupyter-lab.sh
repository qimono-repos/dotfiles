#!/usr/bin/env bash
# Run JupyterLab for the quantum workspace (foreground, one-shot).
# ARM64 path: JupyterLab comes from the uv venv (Guix `jupyter` is not aarch64).
# See docs/jupyter-arm64.md
set -euo pipefail

WS="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"
PORT="${JUPYTER_PORT:-5005}"

if [[ ! -d "$WS" ]]; then
  echo "error: no workspace at $WS — run scripts/install-quantum-python.sh first." >&2
  exit 1
fi

cd "$WS"
exec uv run jupyter lab --no-browser --ip=127.0.0.1 --port="$PORT" "$@"
