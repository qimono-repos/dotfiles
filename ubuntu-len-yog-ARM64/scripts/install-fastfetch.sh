#!/usr/bin/env bash
# Ensure fastfetch is installed (host package manager = apt) and the launch +
# clear display beats are wired via this pack's stow-managed zsh snippet.
#
# Purpose: emergency-reinstall / rebuild path — a machine that already has the
# dotfiles daemon back can run this to restore the fastfetch display behavior
# without hand-editing ~/.zshrc (the old "append fastfetch" anti-pattern).
#
# The display mechanism itself lives in stow-source/shell/.zshrc.d/42-fastfetch.zsh
# (one-shot precmd on launch + interactive `clear` function). This script only:
#   1) installs/refreshes the apt `fastfetch` binary,
#   2) restows `shell` so .zshrc.d/42-fastfetch.zsh is linked,
#   3) verifies and prints status (OK/MISS/WAIT/PLAN).
#
# Idempotent. Usage: ./install-fastfetch.sh [--dry-run]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
STOW_DIR="$ROOT/stow-source"
SNIPPET_SRC="$STOW_DIR/shell/.zshrc.d/42-fastfetch.zsh"
SNIPPET_LINK="$HOME/.zshrc.d/42-fastfetch.zsh"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) echo "usage: $0 [--dry-run]"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

ok()  { printf '  %-46s OK    %s\n' "$1" "$2"; }
bad() { printf '  %-46s MISS  %s\n' "$1" "$2"; }
plan(){ printf '  %-46s PLAN  %s\n' "$1" "$2"; }

echo "=== [ubuntu-len-yog-ARM64] fastfetch (display beats, stow-managed) ==="

# probes
BIN_OK=0; command -v fastfetch >/dev/null 2>&1 && BIN_OK=1
SNIP_OK=0; [[ -L "$SNIPPET_LINK" && -f "$SNIPPET_LINK" ]] && SNIP_OK=1
if (( BIN_OK )); then
  ok "fastfetch binary" "$(command -v fastfetch)  $(fastfetch --version 2>&1 | head -1)"
else
  bad "fastfetch binary" "not on PATH"
fi
if (( SNIP_OK )); then
  ok "zsh snippet" "linked: .zshrc.d/42-fastfetch.zsh"
else
  bad "zsh snippet" "expected stow symlink missing"
fi

# apt reinstallation is destructive/slow; only require the binary, offer worry-free path
if (( BIN_OK && SNIP_OK )); then
  echo
  echo "All present. New shell → fastfetch once; every \`clear\`/\`cls\` → fastfetch again."
  exit 0
fi

if (( DRY_RUN )); then
  (( BIN_OK )) || plan "install fastfetch (apt)" "sudo apt-get install -y fastfetch"
  (( SNIP_OK )) || plan "restow shell" "stow-apply.sh or: stow -d stow-source -t \\$HOME --restow shell"
  exit 0
fi

# install binary via apt (host-native, matches fleet apt package list)
if ! (( BIN_OK )); then
  echo "==> apt-get install fastfetch (needs sudo)"
  sudo apt-get install -y fastfetch || { echo "error: apt install fastfetch failed" >&2; exit 1; }
fi

# link snippet via stow
if ! (( SNIP_OK )); then
  echo "==> restowing shell (wires 42-fastfetch.zsh)"
  if command -v stow >/dev/null 2>&1; then
    stow -d "$STOW_DIR" -t "$HOME" --restow --no-folding shell
  else
    mkdir -p "$HOME/.zshrc.d"
    ln -sfn "$SNIPPET_SRC" "$SNIPPET_LINK"
  fi
fi

# final status
command -v fastfetch >/dev/null 2>&1 && ok "fastfetch binary" "present" || bad "fastfetch binary" "still missing"
[[ -L "$SNIPPET_LINK" && -f "$SNIPPET_LINK" ]] && ok "zsh snippet" "linked" || bad "zsh snippet" "not linked"
echo
echo "Done. New shell → fastfetch once; \`clear\`/\`cls\` → fastfetch again."
