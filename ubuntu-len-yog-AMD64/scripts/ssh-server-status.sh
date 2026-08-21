#!/usr/bin/env bash
# Live "what green means" probe for qimono-localhost as an SSH server.
# No sudo needed. Mirrors the mini-pc status.sh philosophy.
set -uo pipefail

ok()   { printf '  ✓ %s\n' "$1"; }
bad()  { printf '  ✗ %s\n' "$1"; }
row()  { printf '  · %s: %s\n' "$1" "$2"; }

echo "SSH server readiness — $(hostname) — $(date '+%F %T')"

echo "[ daemon ]"
systemctl is-active --quiet ssh.service && ok "ssh.service active" || bad "ssh.service NOT active"
systemctl is-enabled --quiet ssh.service && ok "ssh.service enabled (boot)" || bad "ssh.service not enabled"
systemctl is-active --quiet ssh.socket && row "ssh.socket" "active (socket-activated)" || true

echo "[ listeners ]"
if ss -tln 2>/dev/null | grep -q ':22 '; then
  ok "listening on :22"
  ss -tln | grep ':22 ' | sed 's/^/      /'
else
  bad "nothing listening on :22"
fi

echo "[ keys ]"
n=$(grep -c '^ssh-ed25519 ' "$HOME/.ssh/authorized_keys" 2>/dev/null || true)
if [[ "${n:-0}" -ge 1 ]]; then ok "authorized_keys has ${n} ed25519 key(s)"; else bad "authorized_keys EMPTY — no client can log in with keys"; fi

echo "[ hardening ]"
f="/etc/ssh/sshd_config.d/60-tailscale-hardening.conf"
if [[ -f "$f" ]] && grep -q '^PasswordAuthentication no' "$f"; then
  ok "hardening drop-in applied ($f)"
else
  bad "hardening NOT applied — passwords still accepted (run scripts/install-ssh-hardening.sh after client key works)"
fi

echo "[ global path — tailscale ]"
if command -v tailscale >/dev/null; then
  systemctl is-active --quiet tailscaled && ok "tailscaled active" || bad "tailscaled not active"
  ip=$(tailscale ip -4 2>/dev/null | head -1)
  [[ -n "$ip" ]] && row "tailnet ip" "$ip" || bad "no tailnet ip (run: sudo tailscale up)"
  tailscale status >/dev/null 2>&1 && ok "tailscale status reachable" || bad "tailscale status failed"
else
  bad "tailscale not installed"
fi

echo "[ firewall (best effort) ]"
if command -v ufw >/dev/null && sudo -n ufw status >/dev/null 2>&1; then
  sudo -n ufw status | grep -qiE '22|OpenSSH|Anywhere' && ok "ufw allows ssh" || bad "ufw may block :22 — check: sudo ufw status"
elif command -v ufw >/dev/null; then
  row "ufw" "present; state unknown without sudo (sudo ufw status)"
else
  row "ufw" "not installed"
fi
