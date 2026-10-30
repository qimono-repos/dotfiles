#!/usr/bin/env bash
# Read-only host inventory for the canonical Qimono Ubuntu VPS.
# Writes a sanitized, timestamped snapshot into this repository by default.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VPS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$VPS_ROOT/.." && pwd)"
OUT_DIR="${1:-$VPS_ROOT/inventory}"
HOST="$(hostname -f 2>/dev/null || hostname)"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
OUT="$OUT_DIR/${HOST}-${STAMP}.txt"

mkdir -p "$OUT_DIR"
umask 077

{
  echo "# Qimono VPS inventory"
  echo "captured_at_utc=$STAMP"
  echo "hostname=$HOST"
  echo "user=$(id -un)"
  echo "os_release:"
  cat /etc/os-release 2>/dev/null || true
  echo
  echo "kernel=$(uname -srmo)"
  echo "architecture=$(uname -m)"
  echo "uptime=$(uptime -p 2>/dev/null || uptime)"
  echo
  echo "[cpu]"
  lscpu 2>/dev/null | grep -E '^(Architecture|CPU\(s\)|Model name|Vendor ID|Thread|Core|Socket|Virtualization|Hypervisor vendor):' || true
  echo
  echo "[memory]"
  free -h 2>/dev/null || true
  echo
  echo "[disk]"
  df -hT / 2>/dev/null || true
  echo
  echo "[block_devices]"
  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS 2>/dev/null || true
  echo
  echo "[network_addresses]"
  ip -brief address 2>/dev/null || hostname -I 2>/dev/null || true
  echo
  echo "[default_route]"
  ip route show default 2>/dev/null || true
  echo
  echo "[dns]"
  resolvectl status 2>/dev/null | sed -n '1,45p' || cat /etc/resolv.conf 2>/dev/null || true
  echo
  echo "[services_of_interest]"
  for svc in ssh nginx caddy docker containerd mongod; do
    systemctl is-active "$svc" 2>/dev/null | sed "s/^/$svc=/" || true
  done
  echo
  echo "[runtime_tools]"
  for bin in git curl wget python3 node npm bun java javac gradle docker podman mongosh; do
    if command -v "$bin" >/dev/null 2>&1; then
      printf '%s=%s\n' "$bin" "$(command -v "$bin")"
      case "$bin" in
        java) java -version 2>&1 | head -n 1 ;;
        node) node --version 2>/dev/null || true ;;
        python3) python3 --version 2>/dev/null || true ;;
        gradle) gradle --version 2>/dev/null | grep -m1 '^Gradle ' || true ;;
        git) git --version 2>/dev/null || true ;;
      esac
    else
      printf '%s=not-installed\n' "$bin"
    fi
  done
  echo
  echo "[package_summary]"
  dpkg-query -W -f='${binary:Package}\t${Version}\n' 2>/dev/null | grep -Ei '^(openjdk|temurin|gradle|docker|podman|nginx|caddy|mongodb|git|curl|python3|nodejs)' || true
  echo
  echo "[firewall]"
  if command -v ufw >/dev/null 2>&1; then ufw status 2>&1; else echo "ufw=not-installed"; fi
  echo
  echo "[repo]"
  git -C "$REPO_ROOT" rev-parse --show-toplevel 2>/dev/null || true
  git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true
  git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || true
} > "$OUT"

chmod 600 "$OUT"
echo "Inventory written: $OUT"
echo "Review before committing. This report intentionally does not collect secrets, environment values, full process command lines, or private SSH configuration."
