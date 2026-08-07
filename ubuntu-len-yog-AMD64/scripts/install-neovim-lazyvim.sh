#!/usr/bin/env bash
# Install Neovim & Stow via Guix and link LazyVim config on ubuntu-len-yog-AMD64
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== [ubuntu-len-yog-AMD64] Neovim + LazyVim Setup ==="

# 1. Check & install Guix packages
echo "--> Ensuring Guix packages: neovim, stow, git, ripgrep, fd, gcc-toolchain, tree-sitter"
if command -v guix >/dev/null 2>&1; then
  guix install neovim stow git ripgrep fd gcc-toolchain tree-sitter
else
  echo "error: guix is not installed or not on PATH" >&2
  exit 1
fi

# Ensure guix profile is sourced
if [[ -f "$HOME/.guix-profile/etc/profile" ]]; then
  source "$HOME/.guix-profile/etc/profile"
fi

# 2. Check if apt neovim is present and attempt cleanup
if dpkg -l neovim >/dev/null 2>&1; then
  echo "--> Apt neovim detected. Attempting to remove..."
  if sudo -n true >/dev/null 2>&1; then
    sudo apt remove -y neovim
  else
    echo "Notice: Interactive sudo required to remove apt neovim package."
    echo "Run manually if desired: sudo apt remove -y neovim"
  fi
fi

# Ensure SSL CA certificates are found for Guix applications on foreign distros
if [[ -f "/etc/ssl/certs/ca-certificates.crt" ]]; then
  export SSL_CERT_FILE="${SSL_CERT_FILE:-/etc/ssl/certs/ca-certificates.crt}"
  export SSL_CERT_DIR="${SSL_CERT_DIR:-/etc/ssl/certs}"
  export GIT_SSL_CAINFO="${GIT_SSL_CAINFO:-/etc/ssl/certs/ca-certificates.crt}"
fi

# 3. Apply Stow symlinks
echo "--> Applying stow package (nvim)..."
"$SCRIPT_DIR/stow-apply.sh"

# 4. Bootstrap / sync LazyVim plugins
echo "--> Bootstrapping LazyVim plugins..."
nvim --headless "+Lazy! sync" +qa || true

echo "=== OK: Neovim + LazyVim setup complete! ==="
echo "Launch with: nvim"
