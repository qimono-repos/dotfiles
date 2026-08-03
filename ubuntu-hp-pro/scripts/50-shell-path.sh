#!/usr/bin/env bash
# Ensure interactive shells prefer post-pull guix + user profile.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNIP_DIR="$HOME/.zshrc.d"
SNIP_SRC="$ROOT/stow-source/shell/.zshrc.d/10-guix.zsh"

mkdir -p "$SNIP_DIR"
cp -f "$SNIP_SRC" "$SNIP_DIR/10-guix.zsh"
echo "Installed $SNIP_DIR/10-guix.zsh"

# Hook into ~/.zshrc if present and not already sourcing zshrc.d / zshrc.local
ZSHRC="$HOME/.zshrc"
HOOK='[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"'
LOCAL="$HOME/.zshrc.local"

if [[ ! -f "$LOCAL" ]]; then
  cat > "$LOCAL" << 'EOF'
# qimono ubuntu-hp-pro — load ~/.zshrc.d
if [[ -d "${HOME}/.zshrc.d" ]]; then
  for _s in "${HOME}"/.zshrc.d/*.zsh(N); do
    source "$_s"
  done
  unset _s
fi
EOF
  echo "Created $LOCAL"
fi

if [[ -f "$ZSHRC" ]]; then
  if ! grep -q 'zshrc.local' "$ZSHRC" 2>/dev/null; then
    echo "" >> "$ZSHRC"
    echo "# qimono: machine pack hooks" >> "$ZSHRC"
    echo "$HOOK" >> "$ZSHRC"
    echo "Appended zshrc.local hook to $ZSHRC"
  fi
else
  # minimal zshrc
  cat > "$ZSHRC" << EOF
# minimal zshrc created by ubuntu-hp-pro bootstrap
$HOOK
EOF
  echo "Created $ZSHRC"
fi

# Login shell PATH (merge into .zprofile)
ZPROFILE="$HOME/.zprofile"
MARKER="qimono: Guix post-pull"
if [[ -f "$ZPROFILE" ]] && grep -q "$MARKER" "$ZPROFILE" 2>/dev/null; then
  echo ".zprofile already has guix PATH marker"
else
  cat >> "$ZPROFILE" << 'EOF'

# --- qimono: Guix post-pull (ubuntu-hp-pro) ---
if [[ -d "$HOME/.config/guix/current/bin" ]]; then
  path=("$HOME/.config/guix/current/bin" $path)
fi
if [[ -d "$HOME/.guix-profile/bin" ]]; then
  path=("$HOME/.guix-profile/bin" $path)
fi
typeset -U path PATH
export PATH
# --- end qimono guix ---
EOF
  echo "Updated $ZPROFILE"
fi

# Desktop apps for GNOME
APP_SRC="$HOME/.guix-profile/share/applications"
APP_DST="$HOME/.local/share/applications"
if [[ -d "$APP_SRC" ]]; then
  mkdir -p "$APP_DST"
  for f in "$APP_SRC"/*.desktop; do
    [[ -e "$f" ]] || continue
    ln -sfn "$f" "$APP_DST/$(basename "$f")"
  done
  update-desktop-database "$APP_DST" 2>/dev/null || true
  echo "Linked Guix .desktop files into $APP_DST"
fi

echo "OK: shell PATH hooks installed (open a new terminal)"
