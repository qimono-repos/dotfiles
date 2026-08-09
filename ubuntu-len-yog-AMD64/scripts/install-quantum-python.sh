#!/usr/bin/env bash
# Create (or refresh) a uv project with Qiskit + PennyLane (+ qsharp Python).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"

# Prefer Guix profile tools
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "error: uv not on PATH. Run scripts/install-guix-python-uv.sh first." >&2
  exit 1
fi

mkdir -p "$(dirname "$WS")"
if [[ ! -d "$WS" ]]; then
  echo "==> Creating uv project at $WS"
  # Prefer 3.11/3.12 for scientific wheels; host 3.14 is often too new
  uv init --name quantum-workspace --package "$WS" 2>/dev/null \
    || uv init --name quantum-workspace "$WS"
fi

cd "$WS"

# Pin a CPython uv can manage (independent of host 3.14)
echo "==> Ensuring Python 3.12 for the project"
uv python install 3.12 || true
uv python pin 3.12 || true

echo "==> Adding quantum frameworks"
# Jupyter Notebook UI is Guix-global (package `jupyter`); see scripts/install-jupyter.sh.
# Keep ipykernel here so this venv can be registered as a kernelspec for Guix Jupyter.
# qdk is the current Microsoft Quantum Python package (qsharp is deprecated).
uv add \
  "qiskit>=1.0" \
  "qiskit-aer" \
  "pennylane" \
  "matplotlib" \
  "numpy" \
  "ipykernel" \
  "qdk" \
  || {
    echo "warn: bulk add failed; retrying core packages individually" >&2
    uv add qiskit qiskit-aer pennylane numpy matplotlib ipykernel
    uv add qdk || uv add qsharp || echo "warn: Q# Python package optional"
  }

# Optional accelerators / cloud clients (best-effort)
uv add pennylane-lightning 2>/dev/null || true
uv add pylatexenc 2>/dev/null || true

echo "==> Writing README pointer"
cat > "$WS/README.md" <<EOF
# quantum-workspace

Managed by uv. Created from \`ubuntu-len-yog-AMD64\` bootstrap.

\`\`\`bash
cd $WS
uv run python
# or
uv run pytest
\`\`\`

Frameworks: Qiskit, PennyLane, Q# via qdk (Python).
Machine policy: Guix for python/uv/jupyter; never apt for these libs.
Jupyter UI: Guix package \`jupyter\` + stow config (see install-jupyter.sh).
EOF

# Copy smoke tests into the workspace
EX="$ROOT/tests/smoke-tests"
if [[ -d "$EX" ]]; then
  mkdir -p "$WS/tests/smoke-tests"
  cp -a "$EX/." "$WS/tests/smoke-tests/" 2>/dev/null || true
fi

echo
echo "OK: quantum Python env ready at $WS"
echo "    cd $WS && uv run python tests/smoke-tests/hello_qiskit.py"
echo "Optional: register this venv for Guix Jupyter:"
echo "    uv run python -m ipykernel install --user --name=quantum --display-name='Python (quantum)'"
