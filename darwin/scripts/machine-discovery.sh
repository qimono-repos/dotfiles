#!/usr/bin/env bash
# machine-discovery.sh — probe a macOS host for the darwin pack (safe, read-only).
# Modeled on the Linux packs' machine-discovery.sh, Darwin-flavored.
# Usage: ./machine-discovery.sh | tee machine-$(hostname).txt
set -uo pipefail

hr() { printf '\n======== %s ========\n' "$*"; }

hr "Identity"
echo "date:      $(date -Is 2>/dev/null || date)"
echo "hostname:  $(hostname 2>/dev/null || true)"
echo "whoami:    $(whoami)  uid=$(id -u) gid=$(id -g)"
echo "model:     $(sysctl -n hw.model 2>/dev/null || true)"
echo "chip:      $(sysctl -n machdep.cpu.brand_string 2>/dev/null || sysctl -n hw.optional.arm64 2>/dev/null || echo '?')"
system_profiler SPHardwareDataType 2>/dev/null | sed -n '1,25p' || true

hr "OS (hard gate: macOS 26 Tahoe+)"
sw_vers
echo "arch:      $(uname -m)"
if [[ "$(uname -m)" != "arm64" ]]; then
  echo "  !! NOT Apple Silicon (arm64) — Apple Container will not run."
fi
MAJOR="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
if (( ${MAJOR:-0} >= 26 )); then
  echo "  macOS ${MAJOR} — Tahoe+ gate PASSED (Apple Container supported)."
else
  echo "  !! macOS ${MAJOR} < 26 — Apple Container NOT supported. Update first."
fi

hr "Virtualization / Rosetta"
sysctl -n kern.hv_support 2>/dev/null | grep -q 1 && echo "hv_support: yes" || echo "hv_support: no"
/usr/bin/pgrep -q oahd 2>/dev/null && echo "Rosetta (oahd): running" || echo "Rosetta (oahd): not running (needed to BUILD images only)"
[[ -e /System/Library/Extensions/AppleVirtualization.framework ]] && echo "Virtualization.framework: present" || true

hr "Memory / Disk"
sysctl -n hw.memsize 2>/dev/null | awk '{printf "RAM: %.1f GiB\n", $1/1024/1024/1024}'
df -h / | tail -1

hr "Package managers (ranking aspirational: brew guix(inside machine) apt podman)"
for c in brew guix podman container docker stow uv python3 zsh tmux git; do
  if command -v "$c" >/dev/null 2>&1; then
    printf '  OK  %-10s -> %s\n' "$c" "$(command -v "$c")"
  else
    printf '  --  %-10s (not on PATH)\n' "$c"
  fi
done
if command -v brew >/dev/null 2>&1; then
  echo "brew prefix: $(brew --prefix 2>/dev/null)"
  brew list --formula 2>/dev/null | sort | tr '\n' ' '; echo
fi
for c in container podman; do
  if command -v "$c" >/dev/null 2>&1; then
    echo "$c: $("$c" --version 2>/dev/null | head -1)"
  fi
done
[[ -x /opt/homebrew/bin/container ]] && { echo "container system status:"; /opt/homebrew/bin/container system status 2>&1 | head -10 || true; }
command -v container >/dev/null 2>&1 && { echo "container machine list:"; container machine list 2>&1 | head -10 || true; } || true

hr "Shell / home"
echo "SHELL=$SHELL"
echo "HOME=$HOME"
command -v zsh >/dev/null 2>&1 && echo "zsh: $(zsh --version 2>/dev/null | head -1)" || echo "zsh: not installed (brew)"
[[ -r "$HOME/.zshrc" ]] && echo "zshrc: yes (stow symlink?)  $(readlink "$HOME/.zshrc" 2>/dev/null || true)" || echo "zshrc: no"
[[ -d "$HOME/.zshrc.d" ]] && echo "zshrc.d: $(ls "$HOME/.zshrc.d" 2>/dev/null | tr '\n' ' ')" || echo "zshrc.d: no"
[[ -L "$HOME/.zshrc" ]] && echo "stow-managed .zshrc: yes" || echo "stow-managed .zshrc: no"

hr "Qimono paths"
for p in \
  "$HOME/source/repos/qimono-repos/dotfiles" \
  "$HOME/source/repos/qimono-repos/dotfiles/darwin" \
  "$HOME/.qimono/guix-in-container.sh" \
  "$HOME/AGENTS.md"
do
  if [[ -e "$p" ]]; then echo "  OK  $p"; else echo "  --  $p"; fi
done

hr "Network (hostname only)"
hostname -f 2>/dev/null || true
ifconfig 2>/dev/null | grep -E '^[a-z]|inet ' | head -20 || networksetup -listallhardwareports 2>/dev/null | head -20

hr "Suggested next steps"
cat <<'EOF'
1. Fill MACHINE.md from this output (both Macs).
2. macOS must be 26 (Tahoe) — update before anything else.
3. Bootstrap: ./scripts/bootstrap.sh
4. Guix inside machine: ./scripts/gen-guix-in-container.sh; then
   container machine run qi-dev && sudo bash ~/.qimono/guix-in-container.sh
5. Ranking: 1 brew (host) · 2 guix (in-machine) · 3 apt (in-machine) · 4 podman
EOF

hr "Done"
echo "machine-discovery finished OK"