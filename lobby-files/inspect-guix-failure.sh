#!/usr/bin/env bash
# QIMONO GUIX LOBBY | SIGSEGV inspection | v1.0.0
# Collect a read-only diagnosis of the preceding failed guix pull.
set -Eeuo pipefail
if (( EUID != 0 )); then
  exec sudo bash "$0" "$@"
fi
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
report="/tmp/qimono-guix-failure-${stamp}.log"
exec > >(tee "$report") 2>&1

section() { printf '\n======== %s ========\n' "$*"; }
section "Machine"
uname -a
guix --version | head -n 1 || true
section "RAM"
free -h || true
cat /proc/swaps || true
section "Storage"
df -h / /gnu/store /tmp || true
df -i / /gnu/store /tmp || true
section "Root Guix channels"
if [[ -x /root/.config/guix/current/bin/guix ]]; then
  /root/.config/guix/current/bin/guix describe || true
else
  echo "Root guix pull has not produced a current profile."
fi
section "Recent Guix package-base builder logs"
if [[ -d /var/log/guix/drvs ]]; then
  find /var/log/guix/drvs -type f -name '*guix-packages-base*' \
    -printf '%T@ %p\n' 2>/dev/null |
    sort -nr | head -n 3 | cut -d' ' -f2- |
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    printf '\n--- %s ---\n' "$f"
    case "$f" in
      *.gz) gzip -dc "$f" | tail -n 70 || true ;;
      *.bz2) bzip2 -dc "$f" | tail -n 70 || true ;;
      *.xz) xz -dc "$f" | tail -n 70 || true ;;
      *) tail -n 70 "$f" || true ;;
    esac
  done
fi
section "Kernel OOM, segmentation, disk errors"
dmesg 2>/dev/null |
  grep -Ei 'oom|out of memory|killed process|segfault|I/O error|ext4.*error|usb.*reset' |
  tail -n 60 || true
section "Latest Qimono network transcript"
find /var/log/qimono -maxdepth 1 -name 'network-*.log' -type f \
  -printf '%T@ %p\n' 2>/dev/null |
  sort -nr | head -n 1 | cut -d' ' -f2- |
while IFS= read -r f; do
  [[ -f "$f" ]] && tail -n 35 "$f" || true
done
section "Report"
printf 'Saved to: %s\n' "$report"
