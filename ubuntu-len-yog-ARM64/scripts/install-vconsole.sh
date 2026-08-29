#!/usr/bin/env bash
# Apply this pack's /etc/vconsole.conf and take effect immediately.
#
# NON-DESTRUCTIVE: copies the pack template to /etc/vconsole.conf (per-repo
# convention) but NEVER edits the checked-in source (unlike the old mini-pc
# installer which sed-mutated $ROOT/etc/vconsole.conf). Running with a --font
# override writes a *new* /etc/vconsole.conf only; the source stays pristine;
# a same run without the flag restores the pack default.
#
# Usage: sudo ./install-vconsole.sh [--font FONT]   (e.g. --font Lat2-TerminusBold32x16)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF_SRC="$ROOT/etc/vconsole.conf"
CONF_DST="/etc/vconsole.conf"
FONT_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --font) FONT_OVERRIDE="${2:?--font needs a name}"; shift 2 ;;
    -h|--help) echo "usage: sudo $0 [--font FONT]"; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ $EUID -eq 0 ]] || { echo "error: run with sudo." >&2; exit 1; }
[[ -f "$CONF_SRC" ]] || { echo "error: pack template missing: $CONF_SRC" >&2; exit 1; }

if [[ -n "$FONT_OVERRIDE" ]]; then
  # Build a temp config from the source, override only the FONT line, write /etc.
  tmp="$(mktemp)"
  sed -E "s/^FONT=.*/FONT=${FONT_OVERRIDE}/" "$CONF_SRC" > "$tmp"
  install -m 644 -o root -g root "$tmp" "$CONF_DST"
  rm -f "$tmp"
  echo "==> Installed /etc/vconsole.conf with FONT=${FONT_OVERRIDE}"
else
  install -m 644 -o root -g root "$CONF_SRC" "$CONF_DST"
  echo "==> Installed pack-default /etc/vconsole.conf"
fi

echo "--- /etc/vconsole.conf ---"
grep -E '^FONT=' "$CONF_DST"

# Apply immediately (only meaningful while on a TTY).
FONT="$(sed -nE 's/^FONT=//p' "$CONF_DST" | head -1)"
if command -v setfont >/dev/null 2>&1; then
  setfont "$FONT" 2>/dev/null && echo "OK: TTY font applied: $FONT" \
    || echo "WARN: setfont failed (normal when not on a TTY)."
fi

# Let systemd-vconsole-setup carry it for next boot.
if systemctl list-unit-files 2>/dev/null | grep -q systemd-vconsole-setup; then
  systemctl restart systemd-vconsole-setup 2>/dev/null || true
  echo "==> Restarted systemd-vconsole-setup"
fi

# Ubuntu persistence trap (2026-08-21, seen again 2026-08-28): Ubuntu 26.04
# ships NO systemd-vconsole-setup unit — console-setup.service (setupcon) owns
# the boot-time TTY font via /etc/default/console-setup and silently reverts us
# to Fixed 8x16 every reboot (tiny text on the high-res panel). Keep both files
# agreeing on the same FONT so the larger Terminus Bold survives reboots.
CS_DST="/etc/default/console-setup"
if [[ -f "$CS_DST" ]]; then
  cp -n "$CS_DST" "$CS_DST.qimono.bak" || true
  if grep -q '^FONT=' "$CS_DST"; then
    sed -i "s|^FONT=.*|FONT=\"$FONT\"|" "$CS_DST"
  else
    printf '\n# qimono fleet: keep in sync with /etc/vconsole.conf\nFONT="%s"\n' "$FONT" >> "$CS_DST"
  fi
  # FONT= wins over FONTFACE/FONTSIZE, but comment them out so nothing
  # disagrees later and reverts our size.
  sed -i 's/^FONTFACE=/#FONTFACE=/; s/^FONTSIZE=/#FONTSIZE=/' "$CS_DST"
  echo "==> Synced $CS_DST (console-setup.service applies $FONT at boot)"
fi

echo "Done. Font takes effect on next TTY login or reboot."
echo "Test: Ctrl+Alt+F3 (Terminus Bold) → Ctrl+Alt+F1 to return."
