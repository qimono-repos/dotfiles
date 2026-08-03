#!/usr/bin/env bash
# machine-discovery.sh — explore a host before/after inserting portable home (P5)
# Safe: read-only probes only. No mounts, no package installs, no SD writes.
set -euo pipefail

hr() { printf '\n======== %s ========\n' "$*"; }

hr "Identity"
echo "date:      $(date -Is 2>/dev/null || date)"
echo "hostname:  $(hostname 2>/dev/null || true)"
echo "whoami:    $(whoami)  uid=$(id -u) gid=$(id -g)"
echo "groups:    $(id -nG 2>/dev/null || true)"
hostnamectl 2>/dev/null || true

hr "OS"
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  echo "PRETTY_NAME=${PRETTY_NAME:-}"
  echo "ID=${ID:-} VERSION_ID=${VERSION_ID:-}"
fi
uname -a

hr "CPU / arch"
echo "uname -m: $(uname -m)"
lscpu 2>/dev/null | sed -n '1,40p' || true
echo "virtualization: $(lscpu 2>/dev/null | awk -F: '/Virtualization/{print $2}' | xargs || true)"
[[ -e /dev/kvm ]] && echo "/dev/kvm: present" || echo "/dev/kvm: ABSENT"

hr "Memory"
free -h 2>/dev/null || true

hr "Disk / mounts"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,UUID 2>/dev/null || true
echo
df -hT 2>/dev/null | head -30 || true
echo
echo "Looking for QIMONO-NOMAD label / mmc / common SD patterns:"
lsblk -o NAME,LABEL,UUID,SIZE,MOUNTPOINT 2>/dev/null | grep -iE 'QIMONO|mmc|sd' || echo "(no obvious SD/QIMONO label — insert card or check adapter)"

hr "Package managers (ranking aspirational: guix apt snap podman nix)"
for c in guix apt snap podman nix docker stow uv python3 dotnet rustc cargo flatpak; do
  if command -v "$c" >/dev/null 2>&1; then
    printf '  OK  %-10s -> %s\n' "$c" "$(command -v "$c")"
  else
    printf '  --  %-10s (not on PATH)\n' "$c"
  fi
done
if command -v guix >/dev/null 2>&1; then
  guix --version 2>/dev/null | head -1 || true
  echo "guix packages (user profile):"
  guix package -I 2>/dev/null | head -40 || true
fi
if command -v uv >/dev/null 2>&1; then
  uv --version 2>/dev/null || true
fi
if command -v dotnet >/dev/null 2>&1; then
  dotnet --list-sdks 2>/dev/null || true
fi

hr "Shell / home"
echo "SHELL=$SHELL"
echo "HOME=$HOME"
echo "GUIX_PROFILE=${GUIX_PROFILE:-<unset>}"
[[ -d "$HOME/.guix-profile" ]] && echo "guix-profile: yes" || echo "guix-profile: no"
[[ -r "$HOME/.zshrc" ]] && echo "zshrc: yes" || echo "zshrc: no"
[[ -r "$HOME/.zshrc.local" ]] && echo "zshrc.local: yes" || echo "zshrc.local: no"
[[ -d "$HOME/.zshrc.d" ]] && echo "zshrc.d: $(ls "$HOME/.zshrc.d" 2>/dev/null | tr '\n' ' ')" || true

hr "Qimono paths"
for p in \
  "$HOME/source/repos/qimono-repos/dotfiles" \
  "$HOME/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64" \
  "$HOME/source/repos/qimono-repos/quantum-workspace" \
  "$HOME/AGENTS.md" \
  "$HOME/vega"
 do
  if [[ -e "$p" ]]; then echo "  OK  $p"; else echo "  --  $p"; fi
done

hr "Network (hostname only)"
hostname -f 2>/dev/null || true
ip -br a 2>/dev/null | head -20 || ifconfig 2>/dev/null | head -20 || true

hr "Suggested next steps"
arch="$(uname -m)"
echo "1. If this is a new chassis, save this report: ./scripts/machine-discovery.sh | tee machine-\$(hostname).txt"
echo "2. Arch is: $arch — rebuild Guix/uv if you moved an SD card from another arch."
echo "3. If SD should hold this home, follow: dotfiles/SD-CARD-README.md"
echo "4. Bootstrap pack (when Guix ready):"
echo "     cd \"\$HOME/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64\""
echo "     ./scripts/install-guix-python-uv.sh && ./scripts/stow-apply.sh"
echo "5. Package ranking: 1 guix · 2 apt · 3 snap · 4 podman · 5 nix"

hr "Done"
echo "machine-discovery finished OK"
