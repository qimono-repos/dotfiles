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
echo "[0/6] Host sysctl: Guix userns (Epiphany/WebKit bwrap vs AppArmor)"
# Runtime sysctl -w dies on reboot; pack drop-in must live in /etc/sysctl.d/
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
echo "[1/6] Guix: python, uv, stow, base tools"
"$ROOT/scripts/install-guix-python-uv.sh"

# Ensure stow visible
export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
# shellcheck disable=SC1091
source "$GUIX_PROFILE/etc/profile"

echo
echo "[2/6] Stow: shell + guix-env + quantum + jupyter"
"$ROOT/scripts/stow-apply.sh"

echo
echo "[3/6] Guix Jupyter Notebook + stowed config (127.0.0.1:5005)"
"$ROOT/scripts/install-jupyter.sh"

echo
echo "[4/6] uv: Qiskit + PennyLane + qdk workspace"
"$ROOT/scripts/install-quantum-python.sh"

echo
echo "[5/6] Q# / .NET checks"
"$ROOT/scripts/install-qsharp.sh" || echo "warn: Q# step had issues (non-fatal)"

echo
echo "=============================================="
echo " DONE"
echo " Next:"
echo "   source ~/.zshrc"
echo "   cd \"\${QIMONO_QUANTUM_HOME:-\$HOME/source/repos/qimono-repos/quantum-workspace}\""
echo "   uv run python tests/smoke-tests/run-all.sh"
echo "   systemctl --user start qimono-jupyter.service   # Notebook on :5005"
echo " Host: sysctl kernel.apparmor_restrict_unprivileged_userns  # must be 0 after reboot"
echo " RAM note: this Yoga has ~6.5GiB — keep local sims small."
echo "=============================================="
