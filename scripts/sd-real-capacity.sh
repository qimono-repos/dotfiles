#!/usr/bin/env bash
set -euo pipefail

MEASURE_PROBE_MIB=1
DEV=""
PREPARE=0
MARGIN=5
ASSUME_YES=0

die() {
  echo "error: $*" >&2
  exit 1
}

human_bin() {
  awk -v b="$1" 'BEGIN{u="B KiB MiB GiB TiB";n=1;while(b>=1024&&n<5){b/=1024;n++}split(u,a);printf "%.2f %s",b,a[n]}'
}

human_dec() {
  awk -v b="$1" 'BEGIN{u="B KB MB GB TB";n=1;while(b>=1000&&n<5){b/=1000;n++}split(u,a);printf "%.2f %s",b,a[n]}'
}

num_dec() {
  awk -v b="$1" -v u="$2" 'BEGIN{if(u=="KB")printf "%.2f",b/1e3;else if(u=="MB")printf "%.2f",b/1e6;else if(u=="GB")printf "%.2f",b/1e9;else printf "%d",b}'
}

usage() {
  cat <<EOF
usage: $0 [options] [DEVICE]

Measure the REAL usable capacity of an (possibly counterfeit) SD card and
report it in bytes / KB / MB / GB. With --prepare, wipe and re-format the card
to its real size for use as the qimono-nomad portable home.

options:
  -p, --prepare   wipe, partition (real size minus margin) and format ext4
  -m PCT          safety margin percent subtracted from real size (default 5)
  -y, --yes       skip confirmations in prepare mode
  -h, --help      show this help

DEVICE examples: /dev/mmcblk0, /dev/sda. If omitted, the SD card is
auto-detected (device/type == SD, or a removable sd* disk).

NOTE: the real-capacity estimate is a fast write/read-back probe. For the
authoritative measurement run 'sudo f3probe /dev/<card>'.
EOF
}

[[ $EUID -eq 0 ]] || exec sudo -E "$0" "$@"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p | --prepare) PREPARE=1 ;;
    -m) MARGIN="$2"; shift ;;
    -y | --yes) ASSUME_YES=1 ;;
    -h | --help) usage; exit 0 ;;
    -*) die "unknown option: $1 (see --help)" ;;
    *) DEV="$1" ;;
  esac
  shift
done

pick_device() {
  if [[ -n "$DEV" ]]; then
    [[ "$DEV" == /* ]] || DEV="/dev/$DEV"
    [[ -b "$DEV" ]] || die "not a block device: $DEV"
    [[ -f "/sys/block/${DEV#/dev/}/size" ]] || die "not a whole-disk device: $DEV"
    return
  fi
  local d type rem cand=""
  for d in /sys/block/*; do
    [[ -f "$d/size" ]] || continue
    case "$(basename "$d")" in
      loop* | ram* | zram* | nvme* | md* | sr*) continue ;;
    esac
    type=$(cat "$d/device/type" 2>/dev/null || true)
    rem=$(cat "$d/removable" 2>/dev/null || true)
    if [[ "$type" == "SD" ]] || [[ "$rem" == "1" && "$(basename "$d")" == sd* ]]; then
      cand+=" $(basename "$d")"
    fi
  done
  local n
  n=$(wc -w <<<"$cand")
  case "$n" in
    0) die "no SD card found (insert it, or pass the device explicitly)" ;;
    1) DEV="/dev/${cand## }" ;;
    *) die "multiple removable disks found:$cand — pass one explicitly (e.g. $0 /dev/${cand## })" ;;
  esac
}

probe_persist() {
  local off="$1" pat="/tmp/sd-probe.bin"
  dd if=/dev/urandom of="$pat" bs=1M count="$MEASURE_PROBE_MIB" status=none 2>/dev/null || return 1
  if ! dd if="$pat" of="$DEV" bs=1M seek="$off" count="$MEASURE_PROBE_MIB" conv=fsync status=none 2>/dev/null; then
    return 1
  fi
  sync
  echo 3 >/proc/sys/vm/drop_caches
  if dd if="$DEV" bs=1M skip="$off" count="$MEASURE_PROBE_MIB" status=none 2>/dev/null | cmp -s - "$pat"; then
    return 0
  fi
  return 1
}

measure_real_mib() {
  local lo=1 hi=$((adv_mib - 1)) mid
  [[ $hi -gt 2 ]] || die "card too small"
  probe_persist 1 || die "card does not persist writes even at 1 MiB (dead or unusable)"
  while ((hi - lo > 1)); do
    mid=$(((lo + hi) / 2))
    if probe_persist "$mid"; then
      lo=$mid
    else
      hi=$mid
    fi
  done
  echo $((lo + 1))
}

pick_device

name=${DEV#/dev/}
sectors=$(cat "/sys/block/$name/size")
adv_bytes=$((sectors * 512))
adv_mib=$((sectors / 2048))

echo "probing real capacity of $DEV ($(cat "/sys/block/$name/device/name" 2>/dev/null || echo "?")), advertised ${adv_mib} MiB ..."

real_mib=$(measure_real_mib)
real_bytes=$((real_mib * 1048576))
usable_mib=$((real_mib * (100 - MARGIN) / 100))
usable_bytes=$((usable_mib * 1048576))

printf '\n===== SD card real-capacity report =====\n'
printf 'device:     %s  (%s)\n' "$DEV" "$(cat "/sys/block/$name/device/name" 2>/dev/null || echo 'unknown')"
printf 'advertised: %s  |  %s  (%d bytes)\n' "$(human_dec $adv_bytes)" "$(human_bin $adv_bytes)" "$adv_bytes"
printf '            KB=%s  MB=%s  GB=%s\n' \
  "$(num_dec $adv_bytes KB)" "$(num_dec $adv_bytes MB)" "$(num_dec $adv_bytes GB)"
printf 'real (est.):%s  |  %s  (%d bytes)\n' "$(human_dec $real_bytes)" "$(human_bin $real_bytes)" "$real_bytes"
printf '            KB=%s  MB=%s  GB=%s\n' \
  "$(num_dec $real_bytes KB)" "$(num_dec $real_bytes MB)" "$(num_dec $real_bytes GB)"
printf 'margin:     %s%%  ->  usable %s (%d bytes)\n' \
  "$MARGIN" "$(human_dec $usable_bytes)" "$usable_bytes"
printf '======================================\n'
echo
echo "authoritative check: sudo f3probe $DEV"

if [[ $PREPARE -eq 1 ]]; then
  [[ $usable_mib -ge 1024 ]] || die "usable size below 1 GiB — refusing to prepare"
  if [[ "$name" == mmcblk* ]]; then part="${DEV}p1"; else part="${DEV}1"; fi

  echo
  echo "About to DESTROY all data on $DEV and create:"
  echo "  partition:  1 MiB -> ${usable_mib} MiB"
  echo "  filesystem: ext4, label QIMONO-NOMAD"
  echo "  mount test: /mnt/qimono-nomad"
  if [[ $ASSUME_YES -ne 1 ]]; then
    read -r -p "Type 'yes' to continue: " ans
    [[ "$ans" == "yes" ]] || die "aborted"
  fi

  wipefs -a "$DEV"
  parted -s "$DEV" mklabel gpt
  parted -s "$DEV" mkpart primary ext4 1MiB "${usable_mib}MiB"
  partprobe "$DEV" || true
  udevadm settle
  sleep 2
  [[ -b "$part" ]] || die "partition $part did not appear"

  mkfs.ext4 -F -L QIMONO-NOMAD "$part"
  sync
  e2fsck -f -y "$part"

  mkdir -p /mnt/qimono-nomad
  mount "$part" /mnt/qimono-nomad
  chown 2000:2000 /mnt/qimono-nomad

  uuid=$(blkid -s UUID -o value "$part")
  echo
  echo "OK: mounted $part at /mnt/qimono-nomad"
  echo "UUID: $uuid"
  echo
  echo "Permanent mount (edit /etc/fstab, add):"
  echo "  UUID=$uuid  /home/qimono-nomad  ext4  defaults,nofail  0  2"
  echo
  echo "To unmount now:  sudo umount /mnt/qimono-nomad"
fi
