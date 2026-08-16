#!/usr/bin/env bash
# Shared uv project using Guix python — never uv-downloaded CPython.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"

export GUIX_PROFILE="${HOME}/.guix-profile"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  set +u
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
  set -u
fi

# NumPy / Aer wheels dlopen libz / libstdc++ from the Guix profile.
# Do NOT export that path in this shell — Ubuntu dirname/mkdir/ls then
# load Guix libm and die (GLIBC_2.43). See docs/python-path.md.
uv_wheels() {
  if [[ -d "$GUIX_PROFILE/lib" ]]; then
    env LD_LIBRARY_PATH="$GUIX_PROFILE/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" uv "$@"
  else
    uv "$@"
  fi
}

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
# install-jupyter.sh mkdir -p's the notebook WorkingDirectory, so the folder
# can exist without being a uv project yet.
if [[ ! -f "$WS/pyproject.toml" ]]; then
  echo "==> Creating uv project at $WS"
  uv init --name quantum-workspace "$WS"
fi

cd "$WS"

echo "==> Pinning Guix python: $GUIX_PY"
uv python pin "$GUIX_PY"

echo "==> Adding Qiskit stack (day-1; no PennyLane / qdk)"
uv_wheels add \
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
Do not export \`LD_LIBRARY_PATH=\$HOME/.guix-profile/lib\` in the shell.
The venv \`sitecustomize.py\` preloads Guix libz/libstdc++ for wheels.
EOF

EX="$ROOT/tests/smoke-tests"
if [[ -d "$EX" ]]; then
  mkdir -p "$WS/tests/smoke-tests"
  cp -a "$EX/." "$WS/tests/smoke-tests/" 2>/dev/null || true
fi

SITE="$(
  uv_wheels run python -c "import sysconfig; print(sysconfig.get_path('purelib'))"
)"
if [[ -n "$SITE" && -d "$SITE" ]]; then
  echo "==> Installing sitecustomize (Guix libz/libstdc++ for wheels)"
  cp "$ROOT/scripts/sitecustomize-guix-native.py" "$SITE/sitecustomize.py"
fi

echo "==> Registering Jupyter kernel: Python (quantum)"
uv_wheels run python -m ipykernel install --user --name=quantum --display-name="Python (quantum)"

echo
echo "OK: $WS"
echo "    uv run python tests/smoke-tests/hello_qiskit.py"
