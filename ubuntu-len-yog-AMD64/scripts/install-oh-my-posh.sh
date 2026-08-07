#!/usr/bin/env bash
# Install oh-my-posh, Caskaydia Cove Nerd Font via curl, and stow zsh config with Catppuccin theme
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== [ubuntu-len-yog-AMD64] oh-my-posh + Catppuccin + Cascaydia Cove Font Setup ==="

# 1. Install oh-my-posh via curl
echo "--> Installing / updating oh-my-posh in ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"

# 2. Install Caskaydia Cove Nerd Font via curl
FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
mkdir -p "$FONT_DIR"
if ls "$FONT_DIR"/CaskaydiaCove*.ttf >/dev/null 2>&1; then
  echo "--> Caskaydia Cove Nerd Font already installed in $FONT_DIR."
else
  echo "--> Downloading Caskaydia Cove (CascadiaCode) Nerd Font via curl..."
  TMP_ZIP="$(mktemp --suffix=.zip)"
  curl -fLo "$TMP_ZIP" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
  unzip -o "$TMP_ZIP" -d "$FONT_DIR"
  rm -f "$TMP_ZIP"
  echo "--> Refreshing font cache..."
  fc-cache -fv "$FONT_DIR"
fi

# 3. Handle ~/.zshrc before stowing if it's a regular file
if [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]]; then
  echo "--> Backing up existing non-symlinked ~/.zshrc to ~/.zshrc.bak..."
  mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
fi

# 4. Apply Stow symlinks for shell package (stows .zshrc and .config/oh-my-posh/catppuccin.omp.json)
echo "--> Applying Stow symlinks..."
"$SCRIPT_DIR/stow-apply.sh"

echo "=== OK: oh-my-posh + Catppuccin + Cascaydia Cove setup complete! ==="
echo "Theme config linked at: ~/.config/oh-my-posh/catppuccin.omp.json"
echo "Test prompt rendering with: zsh -c 'source ~/.zshrc && oh-my-posh print primary'"
