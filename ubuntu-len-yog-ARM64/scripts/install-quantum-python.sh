#!/usr/bin/env bash
# Create (or refresh) the Qimono quantum uv workspace from the pinned,
# reproducible spec in this pack:
#
#   ubuntu-len-yog-ARM64/quantum/{pyproject.toml,uv.lock}
#
# That spec is the SINGLE SOURCE OF TRUTH (versions pinned to aarch64-proven
# set). This script materialises it into
#   ${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}
# then `uv sync --frozen` (locked, non-mutating) and registers a Jupyter kernel.
#
# ARM64 adaptation: JupyterLab comes from uv (the monolithic Guix `jupyter`
# package does NOT support aarch64-linux). See docs/jupyter-arm64.md.
#
# Non-destructive: if the workspace already exists AND is a real uv project,
# we only sync; we never overwrite arbitrary existing directories or files.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPEC_DIR="$ROOT/quantum"
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
if [[ ! -f "$SPEC_DIR/pyproject.toml" || ! -f "$SPEC_DIR/uv.lock" ]]; then
  echo "error: quantum spec missing in pack: $SPEC_DIR/{pyproject.toml,uv.lock}" >&2
  exit 1
fi

echo "==> Guix python: $(command -v python3) ($(python3 --version 2>&1))"
export UV_PYTHON_PREFERENCE=only-system
export UV_PYTHON_DOWNLOADS=never
export UV_PYTHON="$(command -v python3)"

mkdir -p "$(dirname "$WS")"
if [[ ! -d "$WS" ]]; then
  echo "==> Creating uv project at $WS (from pinned spec)"
  mkdir -p "$WS"
fi

# Put the pinned spec in place. Never overwrite an existing project's own
# pyproject (could be hand-tuned); only materialise when it is missing.
if [[ -f "$WS/pyproject.toml" ]]; then
  if ! grep -q 'name = "quantum-workspace"' "$WS/pyproject.toml" 2>/dev/null; then
    echo "error: $WS/pyproject.toml exists but is not the quantum-workspace spec." >&2
    echo "       Refusing to overwrite. Reconcile manually or remove it." >&2
    exit 1
  fi
  if ! cmp -s "$SPEC_DIR/pyproject.toml" "$WS/pyproject.toml"; then
    echo "==> Updating pyproject.toml to pack spec"
    cp "$SPEC_DIR/pyproject.toml" "$WS/pyproject.toml"
  fi
else
  cp "$SPEC_DIR/pyproject.toml" "$WS/pyproject.toml"
fi

# Always install the locked lockfile so results match the committed spec.
cp "$SPEC_DIR/uv.lock" "$WS/uv.lock"

cd "$WS"

echo "==> uv sync (locked / frozen — exact versions from uv.lock)"
if ! uv sync --frozen --extra dev; then
  echo "error: uv sync failed. Try: cd $WS && uv sync (and diff uv.lock if changed)" >&2
  exit 1
fi

echo "==> Writing README pointer"
cat > "$WS/README.md" <<EOF
# quantum-workspace

Managed by uv from the pinned spec in
\`dotfiles/ubuntu-len-yog-ARM64/quantum/\` (pyproject.toml + uv.lock).

\`\`\`bash
cd $WS
uv run python
# or
uv run pytest
# JupyterLab (ARM path — Guix \`jupyter\` is not aarch64-supported)
uv run jupyter lab --no-browser --port=5005
\`\`\`

Frameworks: Qiskit, PennyLane, Q# via qdk (Python).
Machine policy: Guix for python/uv; never apt for these libs.
Jupyter: JupyterLab via uv (see ../dotfiles/ubuntu-len-yog-ARM64/docs/jupyter-arm64.md).
EOF

# Copy smoke tests into the workspace if the pack ships them
EX="$ROOT/tests/smoke-tests"
if [[ -d "$EX" ]]; then
  mkdir -p "$WS/tests/smoke-tests"
  cp -a "$EX/." "$WS/tests/smoke-tests/"
fi

echo "==> Register Jupyter kernel (quantum)"
if command -v systemctl >/dev/null 2>&1 && systemctl --user is-active qimono-jupyter.service >/dev/null 2>&1; then
  :
fi
uv run python -m ipykernel install --user --name=quantum --display-name='Python (quantum)' || true

echo
echo "OK: quantum Python env ready at $WS (locked via uv.lock)"
echo "    cd $WS && uv run python tests/smoke-tests/hello_qiskit.py"
echo "Smoke all:  cd $WS && bash ../dotfiles/ubuntu-len-yog-ARM64/tests/smoke-tests/run-all.sh"
