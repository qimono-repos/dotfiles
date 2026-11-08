#!/usr/bin/env bash
# QIMONO GUIX LOBBY | network bootstrap | v1.0.0
# Apply the versioned Guix networking config and prepare wireless networking.
# Run as qi: bash setup-network-in-guix.sh
# Overrides: QIMONO_FIRMWARE=auto|libre|nonguix, QIMONO_WIFI_SSID="My SSID"
set -Eeuo pipefail

PROJECT="qimono-network"
REPO_RAW="https://raw.githubusercontent.com/qimono-repos/dotfiles/main/lobby-files"
RUN_VERSION="v1.0.0"
BOOT_LOG="/var/log/qimono/network-$(date -u +%Y%m%dT%H%M%SZ).log"
FIRMWARE_MODE="${QIMONO_FIRMWARE:-auto}"
GUIX_BIN="guix"
STAGED="/tmp/qimono-network-$$.scm"
SIGNING_KEY="/tmp/qimono-nonguix-signing-key-$$.pub"

say() { printf '\n[%s] %s\n' "$PROJECT" "$*"; }
fail() { printf '[%s] ERROR: %s\n' "$PROJECT" "$*" >&2; exit 1; }
cleanup() { rm -f "$STAGED" "$SIGNING_KEY"; }
trap cleanup EXIT
trap 'printf "\n[%s] FAILED at line %s (status %s)\n" "$PROJECT" "$LINENO" "$?" >&2' ERR

if (( EUID != 0 )); then
  command -v sudo >/dev/null || fail "sudo was not found; rerun from a root shell."
  exec sudo --preserve-env=QIMONO_FIRMWARE,QIMONO_WIFI_SSID bash "$0" "$@"
fi

mkdir -p /var/log/qimono /etc
exec > >(tee -a "$BOOT_LOG") 2>&1

say "Starting $RUN_VERSION"
say "UTC date: $(date -u --iso-8601=seconds)"
say "Log file: $BOOT_LOG"
say "Hostname: $(hostname)"
say "Kernel: $(uname -r)"
say "Available space:"
df -h / /gnu/store 2>/dev/null || true

fetch() {
  local url="$1" output="$2"
  command -v wget >/dev/null || fail "wget is required for initial bootstrapping."
  say "Fetching $url"
  wget -q --show-progress --tries=3 --timeout=45 -O "$output" "$url"
  test -s "$output" || fail "Downloaded empty file: $url"
}

say "Network snapshot"
ip -br a || true
printf '\nWi-Fi sysfs entries:\n'
for entry in /sys/class/net/*/wireless; do
  [[ -e "$entry" ]] && printf '  %s\n' "$entry"
done
printf '\nPCI/USB network inventory (when tools are available):\n'
if command -v lspci >/dev/null; then lspci -nnk | grep -A 4 -Ei 'network|wireless|ethernet|bluetooth' || true; fi
if command -v lsusb >/dev/null; then lsusb || true; fi

HAVE_WIRELESS=0
for entry in /sys/class/net/*/wireless; do
  [[ -e "$entry" ]] && HAVE_WIRELESS=1
done

case "$FIRMWARE_MODE" in
  auto)
    if (( HAVE_WIRELESS )); then FIRMWARE_MODE=libre; else FIRMWARE_MODE=nonguix; fi
    ;;
  libre|nonguix) ;;
  *) fail "QIMONO_FIRMWARE must be auto, libre, or nonguix." ;;
esac
say "Selected mode: $FIRMWARE_MODE"

if [[ "$FIRMWARE_MODE" == "nonguix" ]]; then
  say "Provisioning Nonguix channel for standard Linux kernel and firmware"
  mkdir -p /root/.config/guix
  fetch "$REPO_RAW/channels-nonguix.scm" /root/.config/guix/channels.scm
  say "Updating root's Guix command with the channel"
  guix pull -C /root/.config/guix/channels.scm
  if [[ -x /root/.config/guix/current/bin/guix ]]; then
    GUIX_BIN="/root/.config/guix/current/bin/guix"
  fi

  fetch "https://substitutes.nonguix.org/signing-key.pub" "$SIGNING_KEY"
  say "Authorizing Nonguix substitute signing key"
  "$GUIX_BIN" archive --authorize < "$SIGNING_KEY"
  CONFIG="config-network-nonguix.scm"
  SUBSTITUTE_URLS="https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org"
else
  CONFIG="config-network.scm"
  SUBSTITUTE_URLS=""
fi

fetch "$REPO_RAW/$CONFIG" "$STAGED"
say "Configuration identity"
head -n 4 "$STAGED"

say "Evaluating and building the Guix system derivation"
if [[ -n "$SUBSTITUTE_URLS" ]]; then
  "$GUIX_BIN" system build --substitute-urls="$SUBSTITUTE_URLS" "$STAGED"
else
  "$GUIX_BIN" system build "$STAGED"
fi

say "Applying declarative configuration"
if [[ -n "$SUBSTITUTE_URLS" ]]; then
  "$GUIX_BIN" system reconfigure --substitute-urls="$SUBSTITUTE_URLS" "$STAGED"
else
  "$GUIX_BIN" system reconfigure "$STAGED"
fi

install -m 0644 "$STAGED" /etc/config.scm
say "Applied configuration stored at /etc/config.scm"
head -n 3 /etc/config.scm

say "Networking after reconfiguration"
ip -br a || true
if command -v nmcli >/dev/null 2>&1; then
  nmcli general status || true
  nmcli radio wifi on || true
  nmcli device status || true
  nmcli -f IN-USE,SSID,SIGNAL,SECURITY device wifi list || true
  if [[ -n "${QIMONO_WIFI_SSID:-}" ]]; then
    say "Attempting interactive connection to configured Wi-Fi SSID"
    nmcli --ask device wifi connect "$QIMONO_WIFI_SSID" || true
  fi
else
  say "NetworkManager command will be available via the new system profile."
fi

say "Finished. If Wi-Fi remains invisible, boot the new kernel, then run:"
echo "  nmcli radio wifi on"
echo "  nmcli device wifi list"
echo "  nmcli --ask device wifi connect '<SSID>'"
echo "  ip -br a"
echo "Applied mode: $FIRMWARE_MODE"
echo "Full execution log: $BOOT_LOG"
