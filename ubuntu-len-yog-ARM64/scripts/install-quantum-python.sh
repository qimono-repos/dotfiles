#!/usr/bin/env bash
# Create (or refresh) a uv project with Qiskit + PennyLane (+ qdk Python).
# ARM64 adaptation: JupyterLab is provided via uv (the monolithic Guix
# `jupyter` package does NOT support aarch64-linux). See docs/jupyter-arm64.md.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"

# Prefer Guix profile tools (python, uv). 20-uv-python.zsh policy:
# UV_PYTHON_PREFERENCE=only-system + UV_PYTHON_DOWNLOADS=never → uv must NOT
# download its own CPython; it uses the Guix profile python.
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
export PATH="$GUIX_PROFILE/bin:$PATH"

if ! command -v uv >/dev/null 2>&1; then
  echo "error: uv not on PATH. Run scripts/install-guix-python-uv.sh first." >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 not on PATH from Guix profile." >&2
  exit 1
fi

echo "==> Guix python: $(command -v python3) ($(python3 --version 2>&1))"
export UV_PYTHON_PREFERENCE=only-system
export UV_PYTHON_DOWNLOADS=never
export UV_PYTHON="$(command -v python3)"

mkdir -p "$(dirname "$WS")"
if [[ ! -d "$WS" ]]; then
  echo "==> Creating uv project at $WS"
  uv init --name quantum-workspace "$WS" 2>/dev/null \
    || uv init --name quantum-workspace "$WS"
fi

cd "$WS"

echo "==> Adding quantum frameworks + JupyterLab (via uv, ARM-safe)"
uv add \
  "qiskit>=1.0" \
  "qiskit-aer" \
  "pennylane" \
  "pennylane-lightning" \
  "matplotlib" \
  "numpy" \
  "ipykernel" \
  "jupyterlab" \
  "notebook" \
  "qdk" \
  || {
    echo "warn: bulk add failed; retrying core packages individually" >&2
    uv add qiskit qiskit-aer pennylane numpy matplotlib ipykernel jupyterlab notebook
    uv add qdk || uv add qsharp || echo "warn: Q# Python package optional"
    uv add pennylane-lightning || true
  }

echo "==> Writing README pointer"
cat > "$WS/README.md" <<EOF
# quantum-workspace

Managed by uv. Created from \`ubuntu-len-yog-ARM64\` bootstrap.

\`\`\`bash
cd $WS
uv run python
# or
uv run pytest
# JupyterLab (ARM path — Guix \`jupyter\` is not aarch64-supported)
uv run jupyter lab --no-browser --port=${JUPYTER_PORT:-5005}
\`\`\`

Frameworks: Qiskit, PennyLane, Q# via qdk (Python).
Machine policy: Guix for python/uv; never apt for these libs.
Jupyter: JupyterLab via uv (see ../dotfiles/ubuntu-len-yog-ARM64/docs/jupyter-arm64.md).
EOF

# Copy smoke tests into the workspace if the pack ships them
EX="$ROOT/tests/smoke-tests"
if [[ -d "$EX" ]]; then
  mkdir -p "$WS/tests/smoke-tests"
  cp -a "$EX/." "$WS/tests/smoke-tests/" 2>/dev/null || true
fi

echo
echo "OK: quantum Python env ready at $WS"
echo "    cd $WS && uv run python tests/smoke-tests/hello_qiskit.py"
echo "Optional: register this venv for Jupyter:"
echo "    cd $WS && uv run python -m ipykernel install --user --name=quantum --display-name='Python (quantum)'"
