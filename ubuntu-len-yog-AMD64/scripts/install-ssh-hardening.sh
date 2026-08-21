#!/usr/bin/env bash
# Install SSH server hardening (Part 4 of ~/TAILSCALE-README.md).
# Copies etc/ssh/sshd_config.d/60-tailscale-hardening.conf into /etc and
# restarts ssh. Idempotent. Needs sudo once.
#
# SAFETY GATE: PasswordAuthentication is only switched off after a client
# key is proven. The gate passes when BOTH hold:
#   1. ~/.ssh/authorized_keys has at least one ssh-ed25519 line, AND
#   2. you pass --client-tested after `ssh qimono-localhost` worked from
#      the client machine (key login confirmed from outside).
# Without them the script refuses to apply and prints the exact next steps.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/etc/ssh/sshd_config.d/60-tailscale-hardening.conf"
DST="/etc/ssh/sshd_config.d/60-tailscale-hardening.conf"
CLIENT_TESTED=0
[[ "${1:-}" == "--client-tested" ]] && CLIENT_TESTED=1

if [[ "$(id -u)" -eq 0 ]]; then SUDO=(); else SUDO=(sudo); fi

echo "==> SSH hardening install for qimono-localhost"

# ── gate 1: a client key exists here ────────────────────────────────
keys=$(grep -c '^ssh-ed25519 ' "$HOME/.ssh/authorized_keys" 2>/dev/null || true)
if [[ "${keys:-0}" -lt 1 ]]; then
  echo "REFUSED: ~/.ssh/authorized_keys has no ssh-ed25519 key yet."
  echo "  From each client machine run:"
  echo "    ssh-copy-id qi@qimono-localhost.tailbb5c9e.ts.net"
  echo "  Then re-run this script with --client-tested."
  exit 1
fi
echo "    authorized_keys: ${keys} ed25519 key(s) ✓"

# ── gate 2: human confirms key login worked from the client ─────────
if [[ "$CLIENT_TESTED" -ne 1 ]]; then
  echo "REFUSED: key login not confirmed from a client yet."
  echo "  1) From the client:            ssh qimono-localhost"
  echo "  2) Only if it worked, run:     $0 --client-tested"
  exit 1
fi
echo "    client key login: confirmed by operator ✓"

# ── apply ────────────────────────────────────────────────────────────
[[ -f "$SRC" ]] || { echo "error: missing $SRC" >&2; exit 1; }
echo "    install: $DST"
"${SUDO[@]}" install -m 0644 "$SRC" "$DST"

echo "    validating sshd config..."
"${SUDO[@]}" sshd -t

echo "    restarting ssh (socket-activated Ubuntu)..."
"${SUDO[@]}" systemctl restart ssh.service
systemctl is-enabled --quiet ssh.socket && "${SUDO[@]}" systemctl try-restart ssh.socket || true

echo "==> done. Verify from the CLIENT before closing its session:"
echo "     grep -R '^PasswordAuthentication' /etc/ssh/sshd_config.d/ /etc/ssh/sshd_config"
echo "     ssh qimono-localhost            # must still work (key)"
echo "     ssh -o PubkeyAuthentication=no qimono-localhost   # must FAIL"
"$ROOT/scripts/ssh-server-status.sh" || true
