#!/usr/bin/env bash
# Install oh-my-posh + CaskaydiaCove Nerd Font + Catppuccin theme for ubuntu-mini-pc.
# Fonts already present on this host — script skips if detected.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== [ubuntu-mini-pc] oh-my-posh + Catppuccin + CaskaydiaCove setup ==="

# 1) Install/update oh-my-posh in ~/.local/bin
if ! command -v curl >/dev/null 2>&1; then
  echo "error: curl is required" >&2
  exit 1
fi
mkdir -p "$HOME/.local/bin"
echo "--> Installing / updating oh-my-posh in ~/.local/bin..."
if ! curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"; then
  echo "error: failed to install oh-my-posh" >&2
  exit 1
fi

# 2) Install CaskaydiaCove Nerd Font (skip if already present)
FONT_DIR="$HOME/.local/share/fonts/CaskaydiaCove"
if ls "$FONT_DIR"/CaskaydiaCove*.ttf >/dev/null 2>&1; then
  echo "--> CaskaydiaCove Nerd Font already installed in $FONT_DIR."
else
  echo "--> Downloading CaskaydiaCove Nerd Font..."
  mkdir -p "$FONT_DIR"
  TMP_ZIP="$(mktemp --suffix=.zip)"
  if ! curl -fLo "$TMP_ZIP" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"; then
    echo "error: failed to download CascadiaCode.zip" >&2
    rm -f "$TMP_ZIP"
    exit 1
  fi
  if ! unzip -o "$TMP_ZIP" -d "$FONT_DIR" >/dev/null 2>&1; then
    echo "error: failed to unzip font archive" >&2
    rm -f "$TMP_ZIP"
    exit 1
  fi
  rm -f "$TMP_ZIP"
  echo "--> Refreshing font cache..."
  fc-cache -fv "$FONT_DIR"
fi

# 3) Stow shell package (links .zshrc.d/40-oh-my-posh.zsh + .config/oh-my-posh/)
echo "--> Stowing shell package (oh-my-posh config + snippet)..."
if command -v stow >/dev/null 2>&1; then
  stow -d "$ROOT/stow-source" -t "$HOME" -v --restow --no-folding shell
else
  echo "WARN: stow not found — manually symlinking..."
  mkdir -p "$HOME/.zshrc.d"
  ln -sfn "$ROOT/stow-source/shell/.zshrc.d/40-oh-my-posh.zsh" "$HOME/.zshrc.d/40-oh-my-posh.zsh"
  mkdir -p "$HOME/.config/oh-my-posh"
  ln -sfn "$ROOT/stow-source/shell/.config/oh-my-posh/catppuccin.omp.json" "$HOME/.config/oh-my-posh/catppuccin.omp.json"
fi

# 4) Remove legacy prompt adam1 from ~/.zshrc if present (oh-my-posh takes over prompt)
ZSHRC="$HOME/.zshrc"
if [[ -f "$ZSHRC" && ! -L "$ZSHRC" ]]; then
  if grep -q 'prompt adam1' "$ZSHRC" 2>/dev/null; then
    echo "--> Removing legacy 'prompt adam1' from ~/.zshrc (oh-my-posh owns the prompt now)..."
    sed -i '/^autoload -Uz promptinit$/d' "$ZSHRC"
    sed -i '/^promptinit$/d' "$ZSHRC"
    sed -i '/^prompt adam1$/d' "$ZSHRC"
    sed -i '/^# Set up the prompt$/d' "$ZSHRC"
  fi
fi

# 5) Verify
echo ""
if command -v oh-my-posh >/dev/null 2>&1; then
  echo "OK: oh-my-posh installed at $(command -v oh-my-posh)"
else
  echo "WARN: oh-my-posh not found on PATH yet. Open a new shell or: source ~/.zshrc" >&2
fi

if [[ -f "$HOME/.config/oh-my-posh/catppuccin.omp.json" ]]; then
  echo "OK: Catppuccin theme at ~/.config/oh-my-posh/catppuccin.omp.json"
fi

if [[ -f "$HOME/.zshrc.d/40-oh-my-posh.zsh" ]] || [[ -L "$HOME/.zshrc.d/40-oh-my-posh.zsh" ]]; then
  echo "OK: Init snippet at ~/.zshrc.d/40-oh-my-posh.zsh"
fi

echo ""
echo "Done. Open a new terminal or: source ~/.zshrc"
