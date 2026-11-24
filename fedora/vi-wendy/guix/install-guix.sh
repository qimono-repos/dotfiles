#!/usr/bin/env bash
# QIMONO VI-WENDY | full Guix System installer | v1.2.0
# Run as root from the firmware-enabled x86_64 Nonguix live installer.
# Detect internal HBG4a2 eMMC by hardware identity, not device numbering.
# Deploy the versioned Scheme configuration; no manual Scheme edits.
set -Eeuo pipefail

VERSION=v1.2.0
RAW=https://raw.githubusercontent.com/qimono-repos/dotfiles/main/fedora/vi-wendy/guix
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG=/tmp/vi-wendy-config-$.scm
CHANNEL=/tmp/vi-wendy-channels-$.scm
KEY=/tmp/vi-wendy-nonguix-$$.pub
LOG=/tmp/vi-wendy-install-$(date -u +%Y%m%dT%H%M%SZ).log
ROOT=/mnt
SUBSTITUTES="https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org"

say() { printf '\n[vi-wendy] %s\n' "$*"; }
fail() { say "ERROR: $*"; exit 1; }
on_error() {
  local status="$1" line="$2"
  trap - ERR
  say "Command failed at line $line (exit $status). Transcript: $LOG"
  free -h || true
  df -h / "$ROOT" /gnu/store || true
  exit "$status"
}
trap 'on_error "$?" "$LINENO"' ERR
trap 'rm -f "$CONFIG" "$CHANNEL" "$KEY"' EXIT

download() {
  say "Downloading $1"
  if command -v curl >/dev/null; then
    curl -fL --retry 3 --connect-timeout 30 -o "$2" "$1"
  else
    wget --tries=3 --timeout=60 -O "$2" "$1"
  fi
  [[ -s "$2" ]] || fail "Downloaded empty file from $1"
}
label() { blkid -s LABEL -o value "$1" 2>/dev/null || true; }

(( EUID == 0 )) || fail "Run as root in the Nonguix live installer"
exec > >(tee -a "$LOG") 2>&1
say "Starting installer $VERSION at $(date -u --iso-8601=seconds)"
say "Full Guix System with hostname Qimono, login qi, StumpWM and Nonguix firmware."
say "Target: internal HBG4a2 eMMC, replacing the previous Fedora installation."
[[ -d /sys/firmware/efi/efivars ]] || fail "Installer must boot via UEFI"

for cmd in guix parted partprobe wipefs mkfs.fat mkfs.ext4 mkswap \
           swapon swapoff blkid mount umount mountpoint findmnt \
           herd udevadm ping install; do
  command -v "$cmd" >/dev/null || fail "Installer command is missing: $cmd"
done

say "Memory, swap and live filesystem capacity"
free -h
df -h /

say "Hardware identification of the eMMC install target"
shopt -s nullglob
matches=()
for devpath in /sys/block/mmcblk[0-9]*; do
  [[ "$(basename "$devpath")" =~ ^mmcblk[0-9]+$ ]] || continue
  [[ -r "$devpath/device/name" && -r "$devpath/size" ]] || continue
  model="$(tr -d '[:space:]' < "$devpath/device/name")"
  sectors="$(cat "$devpath/size")"
  [[ "$sectors" =~ ^[0-9]+$ ]] || continue
  bytes=$(( sectors * 512 ))
  say "Device $(basename "$devpath") model=$model size=$(( bytes / 1073741824 )) GiB"
  if [[ "${model,,}" == hbg4a2 ]] &&
     (( bytes > 28 * 1073741824 && bytes < 35 * 1073741824 )); then
    matches+=("/dev/$(basename "$devpath")")
  fi
done
(( ${#matches[@]} == 1 )) ||
  fail "Expected exactly one HBG4a2 eMMC of about 29 GiB; found ${#matches[@]}"
DISK="${matches[0]}"
EFI="${DISK}p1"
SWAP="${DISK}p2"
SYSTEM="${DISK}p3"
say "Selected eMMC: $DISK"

say "Verify internet access and obtain Scheme configuration"
ping -c 1 -W 5 guix.gnu.org
if [[ -f "$SCRIPT_DIR/config.scm" && -f "$SCRIPT_DIR/channels.scm" ]]; then
  say "Using versioned files from local Git checkout: $SCRIPT_DIR"
  install -m 0644 "$SCRIPT_DIR/config.scm" "$CONFIG"
  install -m 0644 "$SCRIPT_DIR/channels.scm" "$CHANNEL"
else
  say "Local configuration unavailable; downloading versioned files"
  download "$RAW/config.scm" "$CONFIG"
  download "$RAW/channels.scm" "$CHANNEL"
fi
head -n 3 "$CONFIG"
grep -q '^;; QIMONO-VI-WENDY-CONFIG-VERSION:' "$CONFIG" ||
  fail "Downloaded config has no version marker"
grep -q '(name "qi")' "$CONFIG" ||
  fail "Downloaded config does not configure login account qi"
grep -q '(host-name "Qimono")' "$CONFIG" ||
  fail "Downloaded config does not configure hostname Qimono"

say "Validate authenticated Guix + Nonguix channel description"
grep -q '^;; QIMONO-VI-WENDY-CHANNELS-VERSION:' "$CHANNEL" ||
  fail "Downloaded channel manifest has no version marker"
grep -q '897c1a470da759236cc11798f4e0a5f7d4d59fbc' "$CHANNEL" ||
  fail "Missing expected Nonguix introduction commit"
grep -Fq '"https://codeberg.org/guix/guix.git"' "$CHANNEL" ||
  fail "Channel manifest does not use the official Codeberg Guix repository"
head -n 3 "$CHANNEL"

say "Authorize Nonguix substitute server before pulling channels"
download https://substitutes.nonguix.org/signing-key.pub "$KEY"
guix archive --authorize < "$KEY"

say "Bootstrap Nonguix packages before evaluating the system config"
# The live ISO provides a firmware-capable kernel, but its Guix command can
# still lack (nongnu packages linux). Pull the authenticated channel into
# root's Guix profile before attempting to evaluate config.scm.
# Reuse a prior successful pull on retry rather than repeating it.
GUIX_CURRENT=/root/.config/guix/current/bin/guix
if [[ -x "$GUIX_CURRENT" ]] &&
   [[ "$("$GUIX_CURRENT" describe --format=channels 2>/dev/null || true)" == *"(name 'nonguix)"* ]]; then
  say "Existing pulled Guix profile already contains the Nonguix channel"
else
  say "Running guix pull with authenticated Nonguix and 1 job/core"
  guix pull --channels="$CHANNEL" --max-jobs=1 --cores=1 \
    --substitute-urls="$SUBSTITUTES" ||
    fail "Nonguix channel pull failed; eMMC has NOT been partitioned"
fi
[[ -x "$GUIX_CURRENT" ]] ||
  fail "Guix pull did not create the updated root Guix command"
export PATH="/root/.config/guix/current/bin:$PATH"
hash -r
say "Active Guix: $(command -v guix)"
ACTIVE_CHANNELS="$(guix describe --format=channels)"
[[ "$ACTIVE_CHANNELS" == *"(name 'nonguix)"* ]] ||
  fail "Active Guix does not include Nonguix; eMMC unchanged"

say "Evaluate configuration with Nonguix enabled before partitioning"
guix system build --dry-run --max-jobs=1 --cores=1 \
  --substitute-urls="$SUBSTITUTES" "$CONFIG" ||
  fail "Guix configuration could not be evaluated; eMMC unchanged"
if [[ "${QIMONO_PREFLIGHT_ONLY:-0}" == "1" ]]; then
  say "Preflight-only mode finished successfully; eMMC unchanged."
  exit 0
fi

say "Check whether the target already has this exact Qimono layout"
if [[ "$(label "$EFI")" == VIWENDYEFI &&
      "$(label "$SWAP")" == vi-wendy-swap &&
      "$(label "$SYSTEM")" == vi-wendy-root ]]; then
  say "Matching partitions detected: reuse for retry, do not format again"
else
  say "Partition eMMC: EFI 512 MiB; swap 2 GiB; ext4 root remainder"
  for partition in "$EFI" "$SWAP" "$SYSTEM"; do
    if findmnt -rn -S "$partition" >/dev/null; then
      umount "$partition"
    fi
    swapoff "$partition" 2>/dev/null || true
  done
  wipefs -a "$DISK"
  parted -s -a optimal "$DISK" \
    mklabel gpt \
    mkpart EFI fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart primary linux-swap 513MiB 2561MiB \
    mkpart primary ext4 2561MiB 100%
  partprobe "$DISK"
  udevadm settle
  for _ in {1..10}; do
    [[ -b "$EFI" && -b "$SWAP" && -b "$SYSTEM" ]] && break
    sleep 1
  done
  [[ -b "$EFI" && -b "$SWAP" && -b "$SYSTEM" ]] ||
    fail "New eMMC partitions did not appear"
  mkfs.fat -F32 -n VIWENDYEFI "$EFI"
  mkswap -L vi-wendy-swap "$SWAP"
  mkfs.ext4 -F -m 1 -L vi-wendy-root "$SYSTEM"
fi

say "Mount root, EFI and activate swap"
if ! mountpoint -q "$ROOT"; then
  mount "$SYSTEM" "$ROOT"
else
  [[ "$(findmnt -n -o SOURCE "$ROOT")" == "$SYSTEM" ]] ||
    fail "$ROOT mounted from an unexpected device"
fi
mkdir -p "$ROOT/boot/efi" "$ROOT/etc" "$ROOT/var/log/qimono"
if ! mountpoint -q "$ROOT/boot/efi"; then
  mount "$EFI" "$ROOT/boot/efi"
else
  [[ "$(findmnt -n -o SOURCE "$ROOT/boot/efi")" == "$EFI" ]] ||
    fail "$ROOT/boot/efi mounted from an unexpected device"
fi
if ! swapon --show=NAME | grep -Fxq "$SWAP"; then
  swapon "$SWAP"
fi
free -h
df -h "$ROOT"

say "Start installer's copy-on-write store for Guix"
if herd status cow-store 2>&1 | grep -Eiq 'running|started'; then
  say "cow-store service already active"
else
  herd start cow-store "$ROOT"
fi

install -m 0644 "$CONFIG" "$ROOT/etc/config.scm"
install -d -m 0755 "$ROOT/etc/guix"
install -m 0644 "$CHANNEL" "$ROOT/etc/guix/channels.scm"
say "Preserved the authenticated Nonguix channel in /etc/guix/channels.scm"

say "Initialize Guix System; low concurrency for this Atom CPU"
guix system init --max-jobs=1 --cores=1 \
  --substitute-urls="$SUBSTITUTES" \
  "$ROOT/etc/config.scm" "$ROOT"

say "Import current Wi-Fi connection for NetworkManager first boot"
if [[ -f /tmp/guix-wifi.conf ]]; then
  WIFI_SSID="$(sed -n 's/^[[:space:]]*ssid="\([^"]*\)".*/\1/p' /tmp/guix-wifi.conf | head -n 1)"
  WIFI_PSK="$(sed -n 's/^[[:space:]]*psk=\([0-9a-fA-F]\{64\}\)[[:space:]]*$/\1/p' /tmp/guix-wifi.conf | head -n 1)"
  if [[ -n "$WIFI_SSID" && ${#WIFI_PSK} -eq 64 &&
        ! "$WIFI_SSID" =~ [[:cntrl:]] ]]; then
    CONNDIR="$ROOT/etc/NetworkManager/system-connections"
    install -d -m 0700 "$CONNDIR"
    umask 077
    {
      printf '[connection]\nid=vi-wendy-wifi\ntype=wifi\ninterface-name=wlan0\nautoconnect=true\n'
      printf '[wifi]\nmode=infrastructure\nssid=%s\n' "$WIFI_SSID"
      printf '[wifi-security]\nkey-mgmt=wpa-psk\npsk=%s\n' "$WIFI_PSK"
      printf '[ipv4]\nmethod=auto\n[ipv6]\nmethod=auto\n'
    } > "$CONNDIR/vi-wendy-wifi.nmconnection"
    chmod 0600 "$CONNDIR/vi-wendy-wifi.nmconnection"
    say "NetworkManager keyfile provisioned locally (secret not printed)"
  else
    say "Wi-Fi keyfile unavailable; configure NetworkManager on first boot"
  fi
else
  say "No /tmp/guix-wifi.conf available to transfer"
fi

say "Save transcript and sync installed files"
cp "$LOG" "$ROOT/var/log/qimono/$(basename "$LOG")"
chmod 0600 "$ROOT/var/log/qimono/$(basename "$LOG")"
sync
say "Guix System installed successfully on $DISK"
say "Hostname Qimono, login account qi, StumpWM window manager"
say "Next: unmount -R /mnt; reboot to internal eMMC"
say "First boot: use a TTY as root to run passwd root and passwd qi"
