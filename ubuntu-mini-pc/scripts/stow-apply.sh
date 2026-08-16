#!/usr/bin/env bash
# Stow shell snippets + jupyter config/unit into $HOME.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_DIR="$ROOT/stow-source"
TARGET="${STOW_TARGET:-$HOME}"
PACKAGES=(shell jupyter)

export GUIX_PROFILE="${HOME}/.guix-profile"
if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
  set +u
  # shellcheck disable=SC1091
  source "$GUIX_PROFILE/etc/profile"
  set -u
fi

if ! command -v stow >/dev/null 2>&1; then
  echo "error: stow not on PATH" >&2
  exit 1
fi

echo "stow → -d stow-source  target=$TARGET  packages=${PACKAGES[*]}"
stow -d "$STOW_DIR" -t "$TARGET" -v --restow --no-folding "${PACKAGES[@]}"
echo "OK: stow applied. Open a new shell or: source ~/.zshrc"
