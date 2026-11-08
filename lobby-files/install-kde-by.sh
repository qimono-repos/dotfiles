#!/usr/bin/env bash
# QIMONO GUIX LOBBY | KDE Plasma + Bluetooth | v1.1.0
# "by" is the requested script name. All OS changes are declarative Guix.
# Run after setup-network-in-guix.sh: bash install-kde-by.sh
# Override low-free-space pause with QIMONO_FORCE=1 (a build can still run out of space).
set -Eeuo pipefail

NAME="qimono-kde"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_RAW="https://raw.githubusercontent.com/qimono-repos/dotfiles/main/lobby-files"
STAGED="/tmp/qimono-kde-$$.scm"
KEY="/tmp/qimono-kde-nonguix-key-$$.pub"
LOG="/var/log/qimono/kde-$(date -u +%Y%m%dT%H%M%SZ).log"
GUIX_BIN="guix"

say() { printf '\n[%s] %s\n' "$NAME" "$*"; }
fail() { printf '[%s] ERROR: %s\n' "$NAME" "$*" >&2; exit 1; }
trap 'printf "[%s] Failure at line %s, status %s\n" "$NAME" "$LINENO" "$?" >&2' ERR
trap 'rm -f "$STAGED" "$KEY"' EXIT

if (( EUID != 0 )); then
  command -v sudo >/dev/null || fail "sudo is unavailable; run from root."
  exec sudo --preserve-env=QIMONO_FORCE bash "$0" "$@"
fi

mkdir -p /var/log/qimono /root/.config/guix
exec > >(tee -a "$LOG") 2>&1

fetch() {
  say "Downloading $1"
  wget -q --show-progress --tries=3 --timeout=45 -O "$2" "$1"
  [[ -s "$2" ]] || fail "Empty download from $1"
}

say "KDE + Bluetooth configuration run (v1.1.0)"
say "System: $(uname -srmo)"
say "KDE preflight: RAM and filesystem space:"
free -h || true
df -h / /gnu/store /tmp
say "KDE planning allowance: at least 6 GiB free is preferable; actual Guix closure depends on shared store dependencies."
say "Existing Guix store footprint:"
du -sh /gnu/store 2>/dev/null || true
FREE_KIB=$(df -Pk / | awk 'NR==2{print $4}')
if (( FREE_KIB < 1048576 )) && [[ "${QIMONO_FORCE:-0}" != "1" ]]; then
  fail "Less than 1 GiB free. KDE derivations need more space. QIMONO_FORCE=1 overrides this check."
fi
if (( FREE_KIB < 6291456 )); then
  say "Available space is less than 6 GiB; full Plasma often requires significantly more."
fi

if [[ -x /root/.config/guix/current/bin/guix ]]; then
  GUIX_BIN=/root/.config/guix/current/bin/guix
fi
if ! "$GUIX_BIN" describe 2>/dev/null | grep -q 'nonguix'; then
  say "Bringing in the Nonguix Linux/firmware channel for the portable desktop"
  if [[ -f "$SCRIPT_DIR/channels-nonguix.scm" ]]; then
    say "Using Nonguix channel definition from local Git checkout"
    install -m 0644 "$SCRIPT_DIR/channels-nonguix.scm" /root/.config/guix/channels.scm
  else
    fetch "$REPO_RAW/channels-nonguix.scm" /root/.config/guix/channels.scm
  fi
  guix pull -C /root/.config/guix/channels.scm
  GUIX_BIN=/root/.config/guix/current/bin/guix
fi

fetch "https://substitutes.nonguix.org/signing-key.pub" "$KEY"
"$GUIX_BIN" archive --authorize < "$KEY"
SUBSTITUTES="https://ci.guix.gnu.org https://bordeaux.guix.gnu.org https://substitutes.nonguix.org"

say "Fetching Guix System definition"
if [[ -f "$SCRIPT_DIR/config-kde.scm" ]]; then
  say "Using config-kde.scm from local Git checkout"
  cp "$SCRIPT_DIR/config-kde.scm" "$STAGED"
else
  fetch "$REPO_RAW/config-kde.scm" "$STAGED"
fi
head -n 4 "$STAGED"

say "Evaluating and downloading the KDE system closure"
"$GUIX_BIN" system build --substitute-urls="$SUBSTITUTES" "$STAGED"

say "Reconfiguring Guix: Plasma, SDDM, Bluetooth, NetworkManager, standard Linux"
"$GUIX_BIN" system reconfigure --substitute-urls="$SUBSTITUTES" "$STAGED"

install -m 0644 "$STAGED" /etc/config.scm
say "Installed declarative OS definition:"
head -n 3 /etc/config.scm

say "Shepherd service inventory"
herd status || true
say "Bluetooth controller inventory"
if command -v bluetoothctl >/dev/null 2>&1; then bluetoothctl list || true; fi
say "Current disk use"
df -h /

say "Install phase complete."
echo "After reboot, the SDDM login screen should offer a Plasma session."
echo "Bluetooth: bluetoothctl list ; bluetoothctl show ; bluetoothctl scan on"
echo "Networking: nmcli device status"
echo "Diagnostic log: $LOG"
