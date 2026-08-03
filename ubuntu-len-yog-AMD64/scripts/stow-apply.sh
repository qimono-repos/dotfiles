#!/usr/bin/env bash
# Apply stow packages from this machine pack into $HOME.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_DIR="$ROOT/stow"
TARGET="${STOW_TARGET:-$HOME}"
PACKAGES=(shell guix-env quantum)

if ! command -v stow >/dev/null 2>&1; then
  echo "error: stow not on PATH. Install with: guix install stow" >&2
  echo "       (then source ~/.guix-profile/etc/profile)" >&2
  exit 1
fi

if [[ ! -d "$STOW_DIR" ]]; then
  echo "error: missing stow dir: $STOW_DIR" >&2
  exit 1
fi

echo "stow → target=$TARGET  packages=${PACKAGES[*]}"
# --no-folding keeps individual files as symlinks (clearer on mixed $HOME)
stow -d "$STOW_DIR" -t "$TARGET" -v --restow --no-folding "${PACKAGES[@]}"
echo "OK: stow packages applied. Open a new shell or: source ~/.zshrc"
