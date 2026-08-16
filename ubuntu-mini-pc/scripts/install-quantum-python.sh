#!/usr/bin/env bash
# Shared uv project using Guix python — never uv-downloaded CPython.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"

export GUIX_PROFILE="${HOME}/.guix-profile"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
fi

if [[ -d "$GUIX_PROFILE/lib" ]]; then
  export LD_LIBRARY_PATH="$GUIX_PROFILE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "error: uv not on PATH. Run scripts/apply-profile.sh first." >&2
  exit 1
fi

GUIX_PY="$(command -v python3 || true)"
case "$GUIX_PY" in
  */.guix-profile/bin/python3|/gnu/store/*)
    ;;
  *)
    echo "error: python3 is not Guix ($GUIX_PY)." >&2
    echo "       source ~/.zshrc (or ~/.guix-profile/etc/profile) and retry." >&2
    exit 1
    ;;
esac

export UV_PYTHON_PREFERENCE=only-system

mkdir -p "$(dirname "$WS")"
if [[ ! -d "$WS" ]]; then
  echo "==> Creating uv project at $WS"
  uv init --name quantum-workspace "$WS"
fi

cd "$WS"

echo "==> Pinning Guix python: $GUIX_PY"
uv python pin "$GUIX_PY"

echo "==> Adding Qiskit stack (day-1; no PennyLane / qdk)"
uv add \
  "qiskit>=1.2" \
  "qiskit-aer" \
  "numpy" \
  "matplotlib" \
  "scipy" \
  "ipykernel"

cat > "$WS/README.md" <<EOF
# quantum-workspace

Shared Qiskit env for this machine. Interpreter is **Guix python**.

    cd $WS
    uv run python tests/smoke-tests/hello_qiskit.py

Do not run \`uv python install\`.
EOF

EX="$ROOT/tests/smoke-tests"
if [[ -d "$EX" ]]; then
  mkdir -p "$WS/tests/smoke-tests"
  cp -a "$EX/." "$WS/tests/smoke-tests/" 2>/dev/null || true
fi

echo "==> Registering Jupyter kernel: Python (quantum)"
uv run python -m ipykernel install --user --name=quantum --display-name="Python (quantum)"

echo
echo "OK: $WS"
echo "    uv run python tests/smoke-tests/hello_qiskit.py"
