#!/usr/bin/env bash
# Run all quantum hello smokes. Prefer: uv run from quantum-workspace.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

run_one() {
  local name="$1" file="$2"
  echo "--- $name ---"
  if command -v uv >/dev/null 2>&1 && [[ -n "${QIMONO_QUANTUM_HOME:-}" && -d "${QIMONO_QUANTUM_HOME}" ]]; then
    (cd "$QIMONO_QUANTUM_HOME" && uv run python "$DIR/$file")
  elif command -v uv >/dev/null 2>&1 && [[ -f "$DIR/../../../../quantum-workspace/pyproject.toml" ]]; then
    (cd "$DIR/../../../../quantum-workspace" && uv run python "$DIR/$file")
  else
    python3 "$file"
  fi
}

status=0
run_one "Qiskit" hello_qiskit.py || status=1
run_one "PennyLane" hello_pennylane.py || status=1
run_one "Q#" hello_qsharp.py || status=1

if [[ $status -eq 0 ]]; then
  echo "ALL OK"
else
  echo "SOME FAILED" >&2
fi
exit "$status"
