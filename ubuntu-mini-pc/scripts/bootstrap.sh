#!/usr/bin/env bash
# Day-1 unattended path: profile → stow → jupyter unit.
# STOPS before password auth (human) and before uv add (network + policy).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== ubuntu-mini-pc bootstrap ==="
echo "    1 apply-profile"
echo "    2 stow + jupyter unit"
echo "    then YOU:  ./scripts/setup-jupyter-auth.sh"
echo "    then:      ./scripts/install-quantum-python.sh"
echo

"$ROOT/scripts/apply-profile.sh"
"$ROOT/scripts/install-jupyter.sh"

echo
echo "=== bootstrap done (auth + quantum-workspace still pending) ==="
echo "    $ROOT/scripts/setup-jupyter-auth.sh"
echo "    $ROOT/scripts/install-quantum-python.sh"
echo "    $ROOT/scripts/status.sh"
