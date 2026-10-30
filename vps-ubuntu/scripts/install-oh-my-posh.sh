#!/usr/bin/env bash
# Install Oh My Posh for the target user's Zsh prompt.
# The Catppuccin theme itself is version-controlled in the VPS Stow package.
set -Eeuo pipefail

HOME_DIR="${HOME:?HOME is not set}"
BIN_DIR="$HOME_DIR/.local/bin"
OMP="$BIN_DIR/oh-my-posh"

mkdir -p "$BIN_DIR"
if [[ -x "$OMP" ]]; then
  echo "Oh My Posh already installed: $("$OMP" version 2>/dev/null | head -n 1)"
else
  command -v curl >/dev/null 2>&1 || { echo "curl is required to install Oh My Posh." >&2; exit 1; }
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  echo "Downloading the official Oh My Posh installer..."
  curl -fsSL https://ohmyposh.dev/install.sh -o "$tmp"
  bash "$tmp" -d "$BIN_DIR"
fi

[[ -x "$OMP" ]] || { echo "Oh My Posh installer completed but binary is missing: $OMP" >&2; exit 1; }
"$OMP" version
echo "Oh My Posh is ready. Catppuccin theme is supplied by the Stow-managed shell package."
