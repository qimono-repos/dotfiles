#!/usr/bin/env bash
# Detect display resolution and set TTY console font proportionally.
# Target feel: CaskaydiaCove Nerd Font Mono 16 at 1920x1080 (≈120 cols × 67 rows)
#
# Reference: CaskaydiaCove Nerd Font Mono 16 at 1920x1080 ≈ 120 cols × 67 rows
# TTY equivalent: Lat2-TerminusBold32x16 (16px wide chars, matching column feel)
#
# Usage: ./console-font-resize.sh [--apply] [--big] [--rows N]
#   --apply     Write to /etc/vconsole.conf and apply immediately (needs sudo)
#   --big       Target fewer rows for bigger text (default: auto-detect for ~67 rows)
#   --rows N    Custom target row count
#   --dry-run   Show recommended font without changing anything (default)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONF_SRC="$ROOT/etc/vconsole.conf"

# ── Font catalog ──────────────────────────────────────
# Format: "FONT_NAME CHAR_WIDTH CHAR_HEIGHT DESCRIPTION"
# Lat2-TerminusBold preferred (Latin-2 + box drawing + bold weight)
declare -a FONTS=(
  "Lat2-TerminusBold14       8  14  tiny"
  "Lat2-TerminusBold16       8  16  small"
  "Lat2-TerminusBold18x10   10  18  compact"
  "Lat2-TerminusBold20x10   10  20  compact-wide"
  "Lat2-TerminusBold22x11   11  22  medium-compact"
  "Lat2-TerminusBold24x12   12  24  medium"
  "Lat2-TerminusBold28x14   14  28  large"
  "Lat2-TerminusBold32x16   16  32  xlarge"
)

# ── Detect resolution ─────────────────────────────────
RES_X=0
RES_Y=0

# Method 1: /sys/class/drm (works on bare metal, no X needed)
for card in /sys/class/drm/card*-*-LVDS-* /sys/class/drm/card*-*-eDP-* /sys/class/drm/card*-*-DP-* /sys/class/drm/card*-*-HDMI-* /sys/class/drm/card*-*-VGA-*; do
  if [[ -f "$card/modes" ]]; then
    read -r MODE < "$card/modes"
    RES_X="${MODE%%x*}"
    RES_Y="${MODE#*x}"
    break
  fi
done

# Method 2: fbcon
if [[ $RES_X -eq 0 ]] && [[ -e /dev/fb0 ]]; then
  if command -v fbset >/dev/null 2>&1; then
    FB_INFO=$(fbset -i 2>/dev/null | grep geometry)
    RES_X=$(echo "$FB_INFO" | awk '{print $2}')
    RES_Y=$(echo "$FB_INFO" | awk '{print $3}')
  fi
fi

# Method 3: xrandr (if X/Wayland session available)
if [[ $RES_X -eq 0 ]] && command -v xrandr >/dev/null 2>&1; then
  XRANDR_OUT=$(xrandr 2>/dev/null | grep ' connected primary' | head -1)
  if [[ -n "$XRANDR_OUT" ]]; then
    RES_X=$(echo "$XRANDR_OUT" | grep -oP '\d+(?=x\d+\+)')
    RES_Y=$(echo "$XRANDR_OUT" | grep -oP 'x\K\d+(?=\+)')
  fi
fi

# Method 4: fallback to 1920x1080
if [[ $RES_X -eq 0 ]]; then
  echo "WARN: Could not detect resolution, defaulting to 1920x1080"
  RES_X=1920
  RES_Y=1080
fi

echo "=== Console Font Resizer ==="
echo "Detected resolution: ${RES_X}x${RES_Y}"
echo ""

# ── Parse arguments (before target calculation) ───────
APPLY=false
TARGET_ROWS=67
for ARG in "$@"; do
  case "$ARG" in
    --apply) APPLY=true ;;
    --big) TARGET_ROWS=33 ;;      # 32x16 font → 33 rows at 1080p (big, readable)
    --rows) shift; TARGET_ROWS="$1"; shift ;;
    --help|-h)
      echo "Usage: $0 [--apply] [--big] [--rows N]"
      echo "  --apply   Write to /etc/vconsole.conf and apply (needs sudo)"
      echo "  --big     Target ~33 rows for bigger text (CaskaydiaCove 16pt feel)"
      echo "  --rows N  Custom target row count"
      exit 0 ;;
  esac
done

# ── Calculate best font ───────────────────────────────
# Reference: 1920x1080 + TerminusBold32x16 (16px wide chars)
#   → 120 cols × 33 rows (≈ CaskaydiaCove 16pt column feel)
#
# Strategy: scale character height proportionally to vertical resolution.
# Default target rows ≈ 67 (small/dense), --big targets ≈ 33 (readable/bold)

TARGET_CHAR_HEIGHT=$((RES_Y / TARGET_ROWS))

echo "Target: ~${TARGET_ROWS} rows → char height ≈ ${TARGET_CHAR_HEIGHT}px"
echo ""

# Find best matching font
BEST_FONT=""
BEST_DIFF=9999

for ENTRY in "${FONTS[@]}"; do
  read -r NAME WIDTH HEIGHT DESC <<< "$ENTRY"
  DIFF=$(( HEIGHT > TARGET_CHAR_HEIGHT ? HEIGHT - TARGET_CHAR_HEIGHT : TARGET_CHAR_HEIGHT - HEIGHT ))

  # Calculate what this font gives us
  COLS=$((RES_X / WIDTH))
  ROWS=$((RES_Y / HEIGHT))

  printf "  %-28s %3dx%-3d  →  %4d cols × %3d rows  (%s)\n" "$NAME" "$WIDTH" "$HEIGHT" "$COLS" "$ROWS" "$DESC"

  if [[ $DIFF -lt $BEST_DIFF ]]; then
    BEST_DIFF=$DIFF
    BEST_FONT="$NAME"
    BEST_WIDTH="$WIDTH"
    BEST_HEIGHT="$HEIGHT"
  fi
done

BEST_COLS=$((RES_X / BEST_WIDTH))
BEST_ROWS=$((RES_Y / BEST_HEIGHT))

echo ""
echo "─────────────────────────────────────────────────────"
echo "BEST MATCH: $BEST_FONT"
echo "  ${BEST_COLS} cols × ${BEST_ROWS} rows at ${RES_X}x${RES_Y}"
echo "  char size: ${BEST_WIDTH}x${BEST_HEIGHT}px"
echo ""

# ── Apply if requested ────────────────────────────────
if $APPLY; then
  if [[ $EUID -ne 0 ]]; then
    echo "error: --apply requires root (sudo)" >&2
    echo "Run: sudo $0 --apply" >&2
    exit 1
  fi

  # Update the config file
  sed -i "s/^FONT=.*/FONT=$BEST_FONT/" "$CONF_SRC"
  cp "$CONF_SRC" /etc/vconsole.conf
  echo "--> Installed to /etc/vconsole.conf"

  # Apply now
  setfont "$BEST_FONT" 2>/dev/null && echo "OK: TTY font changed" || echo "WARN: setfont failed (normal if not on a TTY)"
  echo "Done. Switch to TTY3 (Ctrl+Alt+F3) to see the result."
else
  echo "To apply: sudo $0 --apply"
  echo "For bigger text: sudo $0 --apply --big"
  echo "To preview on a TTY now: sudo setfont $BEST_FONT"
fi
