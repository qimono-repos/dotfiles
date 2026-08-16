#!/usr/bin/env bash
# Stow Jupyter config/unit and enable the user service.
# Package `jupyter` must already be in profile-full.scm (do not guix install here).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export GUIX_PROFILE="${HOME}/.guix-profile"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  set +u
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
  set -u
fi

if ! command -v jupyter >/dev/null 2>&1; then
  echo "error: jupyter not on PATH. Run scripts/apply-profile.sh first." >&2
  exit 1
fi

WS="${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"
mkdir -p "$WS"

echo "==> Stow jupyter + shell"
"$ROOT/scripts/stow-apply.sh"

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user daemon-reload || true
  systemctl --user enable --now qimono-jupyter.service || true
fi

echo
echo "OK: Guix jupyter ready"
command -v jupyter
echo "Config:   ~/.jupyter/jupyter_notebook_config.py  (127.0.0.1:5005)"
echo "Auth:     $ROOT/scripts/setup-jupyter-auth.sh  →  ~/.secrets/jupyter_auth.py"
echo "Status:   systemctl --user status qimono-jupyter.service"
