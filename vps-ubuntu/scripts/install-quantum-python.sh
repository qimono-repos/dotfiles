#!/usr/bin/env bash
# Prepare the repository-owned Python 3.12 quantum workspace using the existing
# Qimono installer and smoke tests from ubuntu-len-yog-AMD64.
set -Eeuo pipefail
PACK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PACK_ROOT/.." && pwd)"
WORKSPACE="$PACK_ROOT/quantum-workspace"
command -v uv >/dev/null 2>&1 || { echo "uv is missing; apply vps-ubuntu/guix/manifest.scm first." >&2; exit 1; }

QIMONO_QUANTUM_HOME="$WORKSPACE" bash "$REPO_ROOT/ubuntu-len-yog-AMD64/scripts/install-quantum-python.sh"
cat > "$WORKSPACE/README.md" <<'EOF'
# VPS quantum workspace

Repository-managed Python 3.12 environment for Qiskit, Qiskit Aer, PennyLane,
QDK, NumPy, Matplotlib, and ipykernel. `uv.lock` pins the resolved dependency
graph. The global Guix profile supplies `uv`; scientific packages stay in this
workspace's ignored `.venv`.

```bash
uv run python --version
uv run python tests/smoke-tests/hello_qiskit.py
uv run python -m ipykernel install --user --name=quantum --display-name='Python (quantum)'
```

No Jupyter server is installed or exposed by this workspace. If one is added,
keep it loopback-bound and put access behind an authenticated channel.
EOF
echo "VPS quantum workspace is ready at $WORKSPACE"
