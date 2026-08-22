#!/usr/bin/env bash
# Point the Ghostty Flatpak sandbox at the stow-managed config.
#
# Why: flatpak builds get XDG_CONFIG_HOME=$HOME/.var/app/<app-id>/config,
# so ghostty never sees ~/.config/ghostty. Its 1.3.x default-file probe
# reads BOTH $XDG_CONFIG_HOME/ghostty/config and .../config.ghostty.
# We link only `config`; ghostty may scaffold an empty config.ghostty
# beside it (harmless, loaded after).
#
# Safe to re-run. See docs/flatpak-guix.md.
set -euo pipefail

APP_ID="com.mitchellh.ghostty"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${ROOT}/stow-source/shell/.config/ghostty/config"

APPDIR="${HOME}/.var/app/${APP_ID}/config/ghostty"
[[ -f "$SRC" ]] || { echo "error: missing source config: $SRC" >&2; exit 1; }

mkdir -p "$APPDIR"
ln -sfn "$SRC" "${APPDIR}/config"
echo "OK: ${APPDIR}/config → ${SRC}"
