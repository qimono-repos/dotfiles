#!/usr/bin/env bash
# Install Guix-global Jupyter Notebook and apply stowed config + user unit.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
fi

if ! command -v guix >/dev/null 2>&1; then
  echo "error: guix not found. Install Guix first." >&2
  exit 1
fi

echo "==> Guix: install jupyter (classic Notebook + ipykernel)"
guix install jupyter

# shellcheck disable=SC1091
source "$GUIX_PROFILE/etc/profile"

if ! command -v jupyter >/dev/null 2>&1; then
  echo "error: jupyter still not on PATH after install" >&2
  exit 1
fi

echo "==> Stow: jupyter package (config + systemd user unit)"
"$ROOT/scripts/stow-apply.sh"

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload || true
  # Machine policy: quantum + mobile frontend laptop — Notebook at login
  systemctl --user enable --now qimono-jupyter.service || true
fi

echo
echo "OK: Guix jupyter ready"
command -v jupyter
jupyter --version 2>/dev/null | head -20 || true
echo
echo "Config:   ~/.jupyter/jupyter_notebook_config.py  (127.0.0.1:5005)"
echo "Auth:     $ROOT/scripts/setup-jupyter-auth.sh  →  ~/.secrets/jupyter_auth.py"
echo "Policy:   enabled at user login (systemctl --user enable)"
echo "Status:   systemctl --user status qimono-jupyter.service"
echo "Stop:     systemctl --user stop qimono-jupyter.service"
echo "Disable:  systemctl --user disable qimono-jupyter.service"
echo
echo "Quantum kernel (optional — Qiskit/PennyLane live in the uv project):"
echo "  cd \"\${QIMONO_QUANTUM_HOME:-\$HOME/source/repos/qimono-repos/quantum-workspace}\""
echo "  uv run python -m ipykernel install --user --name=quantum --display-name='Python (quantum)'"
