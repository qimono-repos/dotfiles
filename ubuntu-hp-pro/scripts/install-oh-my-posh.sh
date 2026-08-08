#!/usr/bin/env bash
# Install oh-my-posh, Cascaydia Cove Nerd Font, and Catppuccin theme for ubuntu-hp-pro.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== [ubuntu-hp-pro] oh-my-posh + Catppuccin + Cascaydia Cove setup ==="

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

# 2) Install Cascaydia Cove Nerd Font via curl
FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
mkdir -p "$FONT_DIR"
if ls "$FONT_DIR"/CaskaydiaCove*.ttf >/dev/null 2>&1; then
  echo "--> Caskaydia Cove Nerd Font already installed in $FONT_DIR."
else
  echo "--> Downloading Caskaydia Cove Nerd Font..."
  TMP_ZIP="$(mktemp --suffix=.zip)"
  if ! curl -fLo "$TMP_ZIP" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"; then
    echo "error: failed to download CascaydiaCode.zip" >&2
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

# 3) Link oh-my-posh config and prompt init files
ZSHRC_D_DIR="$HOME/.zshrc.d"
mkdir -p "$ZSHRC_D_DIR"
ln -sfn "$ROOT/stow-source/shell/.zshrc.d/40-oh-my-posh.zsh" "$ZSHRC_D_DIR/40-oh-my-posh.zsh"

OM_POSH_CONFIG_DIR="$HOME/.config/oh-my-posh"
mkdir -p "$OM_POSH_CONFIG_DIR"
ln -sfn "$ROOT/stow-source/shell/.config/oh-my-posh/catppuccin.omp.json" "$OM_POSH_CONFIG_DIR/catppuccin.omp.json"

# 4) Ensure ~/.zshrc loads ~/.zshrc.local
ZSHRC="$HOME/.zshrc"
ZSHRC_LOCAL="$HOME/.zshrc.local"
HOOK='[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"'

if [[ -f "$ZSHRC" && ! -L "$ZSHRC" ]]; then
  if ! grep -q 'zshrc.local' "$ZSHRC" 2>/dev/null; then
    echo "--> Backing up existing ~/.zshrc to ~/.zshrc.bak..."
    mv "$ZSHRC" "$HOME/.zshrc.bak"
    cat > "$ZSHRC" <<EOF
# qimono ubuntu-hp-pro zsh initialization
$HOOK
EOF
  fi
fi

if [[ ! -f "$ZSHRC" ]]; then
  cat > "$ZSHRC" <<EOF
# qimono ubuntu-hp-pro zsh initialization
$HOOK
EOF
  echo "Created $ZSHRC"
elif ! grep -q 'zshrc.local' "$ZSHRC" 2>/dev/null; then
  echo "" >> "$ZSHRC"
  echo "# qimono: load ~/.zshrc.local" >> "$ZSHRC"
  echo "$HOOK" >> "$ZSHRC"
  echo "Appended ~/.zshrc.local hook to $ZSHRC"
fi

if [[ ! -f "$ZSHRC_LOCAL" ]]; then
  cat > "$ZSHRC_LOCAL" <<'EOF'
# qimono ubuntu-hp-pro local zsh hooks
if [[ -d "${HOME}/.zshrc.d" ]]; then
  for _s in "${HOME}"/.zshrc.d/*.zsh(N); do
    source "$_s"
  done
  unset _s
fi
EOF
  echo "Created $ZSHRC_LOCAL"
elif ! grep -q 'qimono ubuntu-hp-pro local zsh hooks' "$ZSHRC_LOCAL" 2>/dev/null; then
  cat >> "$ZSHRC_LOCAL" <<'EOF'
# qimono ubuntu-hp-pro local zsh hooks
if [[ -d "${HOME}/.zshrc.d" ]]; then
  for _s in "${HOME}"/.zshrc.d/*.zsh(N); do
    source "$_s"
  done
  unset _s
fi
EOF
  echo "Updated $ZSHRC_LOCAL"
fi

# 5) Ensure ~/.zprofile includes ~/.local/bin in PATH for login shells
ZPROFILE="$HOME/.zprofile"
MARKER="# qimono: local bin path"
if [[ -f "$ZPROFILE" ]]; then
  if ! grep -q "$MARKER" "$ZPROFILE" 2>/dev/null; then
    cat >> "$ZPROFILE" <<'EOF'
$MARKER
if [[ -d "$HOME/.local/bin" ]]; then
  path=("$HOME/.local/bin" $path)
  typeset -U path PATH
  export PATH
fi
EOF
    echo "Updated $ZPROFILE"
  fi
elif [[ ! -f "$ZPROFILE" ]]; then
  cat > "$ZPROFILE" <<'EOF'
$MARKER
if [[ -d "$HOME/.local/bin" ]]; then
  path=("$HOME/.local/bin" $path)
  typeset -U path PATH
  export PATH
fi
EOF
  echo "Created $ZPROFILE"
fi

# 6) Display status
if command -v oh-my-posh >/dev/null 2>&1; then
  echo "OK: oh-my-posh installed at $(command -v oh-my-posh)"
else
  echo "WARN: oh-my-posh not found on PATH yet. Open a new shell or source ~/.zshrc." >&2
fi

if [[ -f "$HOME/.config/oh-my-posh/catppuccin.omp.json" ]]; then
  echo "OK: Catppuccin theme file linked at ~/.config/oh-my-posh/catppuccin.omp.json"
fi

echo "Run: zsh -c 'source ~/.zshrc && oh-my-posh print primary' to verify prompt rendering."
