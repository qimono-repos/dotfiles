#!/usr/bin/env bash
# Idempotent bootstrap for ubuntu-len-yog-ARM64 (Snapdragon) quantum + Guix-first.
# NOTE: GNU Guix itself must be installed first (sudo):
#   sudo ./scripts/install-guix-binary.sh
#   sudo ./scripts/finish-guix-binary.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "=============================================="
echo " bootstrap: ubuntu-len-yog-ARM64"
echo " host: $(hostname) | $(uname -m)"
echo " pack: $ROOT"
echo " policy: 1 guix · 2 apt · 3 snap · 4 podman"
echo "=============================================="

if ! command -v guix >/dev/null 2>&1; then
  echo "error: GNU Guix is required first." >&2
  echo "  sudo ./scripts/install-guix-binary.sh && sudo ./scripts/finish-guix-binary.sh" >&2
  exit 1
fi

echo
echo "[0/5] Host sysctl: Guix userns (Epiphany/WebKit bwrap vs AppArmor)"
need_sysctl=0
if [[ ! -f /etc/sysctl.d/99-guix-userns.conf ]]; then
  need_sysctl=1
fi
if [[ "$(cat /proc/sys/kernel/apparmor_restrict_unprivileged_userns 2>/dev/null || echo 1)" != "0" ]]; then
  need_sysctl=1
fi
if [[ "$need_sysctl" -eq 1 ]]; then
  "$ROOT/scripts/install-host-sysctl.sh"
else
  echo "    already applied (99-guix-userns.conf + value 0)"
fi

echo
echo "[1/5] Guix: python, uv, stow, base tools"
"$ROOT/scripts/install-guix-python-uv.sh"

export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
export PATH="$GUIX_PROFILE/bin:$PATH"

echo
echo "[2/5] Stow: shell + guix-env + quantum + jupyter"
"$ROOT/scripts/stow-apply.sh"

echo
echo "[3/5] uv: Qiskit + PennyLane + qdk workspace (+ JupyterLab via uv)"
"$ROOT/scripts/install-quantum-python.sh"

echo
echo "[4/5] Enable + start JupyterLab user service (127.0.0.1:5005)"
systemctl --user daemon-reload
systemctl --user enable --now qimono-jupyter.service

echo
echo "=============================================="
echo " DONE"
echo " Next:"
echo "   source ~/.zshrc"
echo "   cd \"\${QIMONO_QUANTUM_HOME:-\$HOME/source/repos/qimono-repos/quantum-workspace}\""
echo "   uv run python tests/smoke-tests/run-all.sh"
echo "   open http://127.0.0.1:5005   # JupyterLab (uv, ARM64)"
echo " Host: sysctl kernel.apparmor_restrict_unprivileged_userns  # must be 0 after reboot"
echo "=============================================="
