#!/usr/bin/env bash
# Apply stow packages from the darwin pack into $HOME (macOS host).
# Source dir is named stow-source/ so the -d flag is self-explanatory.
# The SAME $HOME is mirrored into `container machine qi-dev`, so the stowed
# shell config also materializes inside Linux (snippets are OS-guarded there).
# Usage: ./scripts/stow-apply.sh   (requires `brew install stow`)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW_DIR="$ROOT/stow-source"
TARGET="${STOW_TARGET:-$HOME}"
PACKAGES=(shell)

if ! command -v stow >/dev/null 2>&1; then
  echo "error: stow not on PATH. Install with: brew install stow" >&2
  exit 1
fi

if [[ ! -d "$STOW_DIR" ]]; then
  echo "error: missing stow-source dir: $STOW_DIR" >&2
  exit 1
fi

echo "stow → -d stow-source  target=$TARGET  packages=${PACKAGES[*]}"
stow -d "$STOW_DIR" -t "$TARGET" -v --restow --no-folding "${PACKAGES[@]}"
echo "OK: stow packages applied. Open a new shell or: source ~/.zshrc"