#!/usr/bin/env bash
# Idempotent bootstrap for ubuntu-len-yog-AMD64 quantum + Guix-first dev env.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=============================================="
echo " bootstrap: ubuntu-len-yog-AMD64"
echo " host: $(hostname) | $(uname -m)"
echo " pack: $ROOT"
echo " policy: 1 guix · 2 apt · 3 snap · 4 podman"
echo "=============================================="

if ! command -v guix >/dev/null 2>&1; then
  echo "error: GNU Guix is required first." >&2
  echo "  See: ~/source/repos/qimono-repos/install-guix-ready.sh" >&2
  exit 1
fi

echo
echo "[1/4] Guix: python, uv, stow, base tools"
"$ROOT/scripts/install-guix-python-uv.sh"

# Ensure stow visible
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
# shellcheck disable=SC1091
source "$GUIX_PROFILE/etc/profile"

echo
echo "[2/4] Stow: shell + guix-env + quantum"
"$ROOT/scripts/stow-apply.sh"

echo
echo "[3/4] uv: Qiskit + PennyLane + qsharp workspace"
"$ROOT/scripts/install-quantum-python.sh"

echo
echo "[4/4] Q# / .NET checks"
"$ROOT/scripts/install-qsharp.sh" || echo "warn: Q# step had issues (non-fatal)"

echo
echo "=============================================="
echo " DONE"
echo " Next:"
echo "   source ~/.zshrc"
echo "   cd \"\${QIMONO_QUANTUM_HOME:-\$HOME/source/repos/qimono-repos/quantum-workspace}\""
echo "   uv run python examples/quantum-hello/run-all.sh"
echo " RAM note: this Yoga has ~6.5GiB — keep local sims small."
echo "=============================================="
