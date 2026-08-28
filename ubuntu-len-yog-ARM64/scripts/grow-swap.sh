#!/usr/bin/env bash
# Qimono fleet — size the local swap to 2x physical RAM, as /swap.img.
#
# For ubuntu-len-yog-ARM64 (Snapdragon, 30 GiB RAM) the target is 60 GiB.
# This REPLACES the existing /swap.img (default was 8 GiB) so there is a single
# swap file, matching the machine policy (RAM-hungry Oryon sims / local LLM).
#
# --- WARNING: PRIVILEGED + DISRUPTIVE to available swap, but NOT destructive
# --- to files. Requires root (sudo). Briefly swaps OFF while resizing.
# --- Safe on a running system: adds the file back atomically and /etc/fstab
# --- already has `sw 0 0` so it survives reboot unchanged.
#
# Idempotent: safe to re-run; re-sizes to target if below, skips if equal.
# Usage:  sudo ./grow-swap.sh [TARGET_GiB|--auto]
#   --auto   TARGET = (MemTotal_Bytes / 2^30) * 2  rounded to GiB
set -euo pipefail

TARGET_GIB=""
for arg in "$@"; do
  case "$arg" in
    --auto) TARGET_GIB="auto" ;;
    --help|-h)
      echo "usage: sudo $0 [GIB | --auto]"; echo "  (default --auto = 2x physical RAM)"; exit 0 ;;
    *) TARGET_GIB="$arg" ;;
  esac
done

[[ $EUID -eq 0 ]] || { echo "error: run with sudo (swap resize needs root)." >&2; exit 1; }

# Physical RAM in bytes from /proc/meminfo
MEM_BYTES=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)   # KiB
MEM_GIB=$(( MEM_BYTES / (1024*1024) ))                    # floor GiB

if [[ -z "$TARGET_GIB" || $TARGET_GIB == "auto" ]]; then
  TARGET_MIB=$(( MEM_GIB * 2 * 1024 ))
else
  TARGET_MIB=$(( TARGET_GIB * 1024 ))
fi

echo "=== Swap sizing on $(hostname) ==="
echo "Physical RAM : ~${MEM_GIB} GiB"
echo "Target swap  : $(( TARGET_MIB / 1024 )) GiB (${TARGET_MIB} MiB)"
echo "Current /swap.img: $(stat -c %s /swap.img 2>/dev/null | awk '{printf "%.1f GiB\n", $1/1073741824}')  (or absent)"
echo

CUR_MIB=0
if [[ -f /swap.img ]]; then CUR_MIB=$(( $(stat -c %s /swap.img 2>/dev/null || echo 0) / 1024 / 1024 )); fi

if [[ $CUR_MIB -ge $TARGET_MIB ]]; then
  echo "OK: /swap.img is already >= target ($(( CUR_MIB / 1024 )) GiB). Nothing to do."
  exit 0
fi

if [[ -f /swap.img ]]; then
  echo "Swapping OFF current /swap.img…"
  swapoff /swap.img
  if [[ $CUR_MIB -gt 0 ]]; then
    read -r -p "Remove old /swap.img ($(( CUR_MIB / 1024 )) GiB) before creating ${TARGET_GIB} GiB? [y/N] " ans
    case "${ans:-}" in y|Y|yes|YES) rm -f /swap.img ;; *) echo "keeping old file (not used)" ;; esac
  fi
fi

echo "Creating ${TARGET_MIB} MiB /swap.img (this may take a minute)..."
fallocate -l "${TARGET_MIB}M" /swap.img 2>/dev/null \
  || dd if=/dev/zero of=/swap.img bs=1M count="$TARGET_MIB" status=progress
chmod 600 /swap.img
mkswap /swap.img
swapon /swap.img

# Ensure fstab entry so it survives reboot (idempotent).
if ! grep -qsE '^/swap\.img\s' /etc/fstab; then
  echo '/swap.img       none    swap    sw      0       0' >> /etc/fstab
  echo "Added /etc/fstab entry."
fi

echo
echo "Ok — new swap:"
swapon --show --output=NAME,TYPE,SIZE,USED,PRIO || swapon -s
echo "Done. Swap sizing persists across reboot (see /etc/fstab)."
