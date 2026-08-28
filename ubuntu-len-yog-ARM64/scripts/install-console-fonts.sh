#!/usr/bin/env bash
# Ensure Linux console (TTY) fonts are available and pick a Terminus Bold size
# for ubuntu-len-yog-ARM64. Installs apt packages if needed (sudo).
#
# The TTY font system only supports bitmap fonts; Terminus Bold is the closest
# match to the Caskaydia Cove Nerd Font look used in Ghostty. The actual
# /etc/vconsole.conf font is applied by scripts/install-vconsole.sh; this script
# just guarantees the font files exist and prints the auto-chosen size.
#
# Idempotent; safe to re-run. Usage: sudo ./install-console-fonts.sh
set -euo pipefail

FONT_DIR="/usr/share/consolefonts"
FONTS=(Lat2-TerminusBold14 Lat2-TerminusBold16 Lat2-TerminusBold18x10 \
       Lat2-TerminusBold22x11 Lat2-TerminusBold24x12 Lat2-TerminusBold28x14 \
       Lat2-TerminusBold32x16)

PKGS=()
for p in kbd console-setup console-setup-linux; do
  dpkg -s "$p" >/dev/null 2>&1 || PKGS+=("$p")
done

if (( ${#PKGS[@]} )); then
  echo "==> Installing console packages: ${PKGS[*]}"
  apt-get update -qq
  apt-get install -y "${PKGS[@]}"
else
  echo "==> Console packages already present."
fi

echo
echo "==> Terminus font files on this host:"
MISSING=0
for f in "${FONTS[@]}"; do
  if [[ -f "$FONT_DIR/$f.psf.gz" ]]; then
    printf '   OK   %s\n' "$f"
  else
    printf '   MISS %s\n' "$f"
    MISSING=1
  fi
done
(( MISSING )) && { echo "note: some Terminus sizes missing; reinstall kbd/console-setup." >&2; }

echo
echo "Recommend: run sudo ./scripts/install-vconsole.sh (Terminus Bold, ~67 rows)"
echo "Preview now:  sudo setfont Lat2-TerminusBold32x16"
