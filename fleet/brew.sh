#!/usr/bin/env bash
# Qimono fleet bootstrap — macOS (Homebrew path).
#
# macOS packages: Homebrew (host) is manager #1; Guix is manager #2 but runs
# INSIDE the Apple `container machine` (Linux), not on macOS directly — see the
# darwin pack (darwin/README.md) for that layer. This script:
#   1. Ensure Xcode Command Line Tools (xcode-select --install; one human dialog).
#   2. Install Homebrew (NONINTERACTIVE=1) into /opt/homebrew (Apple Silicon)
#      or /usr/local (Intel).
#   3. brew bundle from the checked-in fleet/Brewfile.
#   4. Clone the PUBLIC dotfiles repo over HTTPS.
#   5. macOS 26 Tahoe gate, then dispatch to the darwin pack bootstrap.sh
#      (stow shell, Apple Container + Podman, dev machine, Guix-in-container
#      generators). Older macOS falls back to a stow-only path.
#
# Run via the curl|sh entrypoint (fleet/install) on macOS.

set -euo pipefail

QIMONO_SRC="${QIMONO_SRC:-${HOME}/source/repos/qimono-repos}"
REPO_DIR="${QIMONO_SRC}/dotfiles"
REPO_URL="https://github.com/qimono-repos/dotfiles.git"

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }

echo "=== brew.sh — macOS Homebrew bootstrap on $(hostname) ==="
echo

# ---- 1. Xcode Command Line Tools -------------------------------------------
echo "--- Xcode Command Line Tools ---"
if xcode-select -p >/dev/null 2>&1; then
  ok "Xcode CLT" "$(xcode-select -p)"
else
  echo "Installing Xcode Command Line Tools — a dialog will appear; click Install."
  xcode-select --install || true
  echo "Waiting for Xcode CLT to finish (this can take several minutes)..."
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
  ok "Xcode CLT" "installed"
fi

# ---- 2. Homebrew ------------------------------------------------------------
echo "--- Homebrew ---"
if command -v brew >/dev/null 2>&1; then
  ok "brew" "$(brew --version 2>/dev/null | head -1)"
  eval "$(brew shellenv)"
elif [[ -x /opt/homebrew/bin/brew ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ok "brew" "$(brew --version 2>/dev/null | head -1)"
elif [[ -x /usr/local/bin/brew ]]; then
  export PATH="/usr/local/bin:$PATH"
  eval "$(/usr/local/bin/brew shellenv)"
  ok "brew" "$(brew --version 2>/dev/null | head -1)"
else
  echo "--- installing Homebrew (NONINTERACTIVE=1) ---"
  export NONINTERACTIVE=1
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    export PATH="/opt/homebrew/bin:$PATH"; eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    export PATH="/usr/local/bin:$PATH"; eval "$(/usr/local/bin/brew shellenv)"
  fi
  ok "brew" "installed at $(command -v brew)"
fi

# ---- 3. brew bundle ----------------------------------------------------------
echo "--- brew bundle (fleet/Brewfile) ---"
BREWFILE_DIR=""
for d in "$REPO_DIR/fleet" "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; do
  if [[ -f "$d/Brewfile" ]]; then BREWFILE_DIR="$d"; break; fi
done
if [[ -n "$BREWFILE_DIR" ]]; then
  brew bundle --file="$BREWFILE_DIR/Brewfile"
  ok "brew bundle" "apps/formulae installed"
else
  warn "Brewfile" "not found — skipping brew bundle"
fi

# ---- 4. clone + dispatch to a macOS pack -------------------------------------
echo "--- fetching dotfiles repo (public, HTTPS) ---"
mkdir -p "${QIMONO_SRC}"
if [[ -d "$REPO_DIR/.git" ]]; then
  ok "dotfiles repo" "already present"
else
  git clone "$REPO_URL" "$REPO_DIR"
  ok "dotfiles repo" "cloned to ${REPO_DIR}"
fi

# macOS 26 Tahoe gate (Apple Container hard requirement).
MAJOR="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
if [[ "$(uname -m)" == "arm64" ]] && (( ${MAJOR:-0} >= 26 )) && [[ -x "$REPO_DIR/darwin/scripts/bootstrap.sh" ]]; then
  echo "--- dispatching to darwin pack bootstrap (macOS $MAJOR / arm64) ---"
  bash "$REPO_DIR/darwin/scripts/bootstrap.sh"
elif command -v stow >/dev/null 2>&1 && [[ -d "$REPO_DIR/gnu-guix" ]]; then
  # Older macOS / non-Apple-Silicon: legacy stow-only path (no container layer).
  warn "darwin pack" "not applicable (macOS $MAJOR / $(uname -m)) — legacy stow only"
  ( cd "$REPO_DIR" && stow -d gnu-guix/stow-source -t "$HOME" --restow shell ) 2>/dev/null || \
    warn "stow" "skipped (stow not installed for macOS shell stow)"
else
  warn "darwin pack" "bootstrap.sh missing or macOS < 26 — manually: stow + brew bundle"
fi

echo
echo "=== brew.sh done. brew bundle contents are in fleet/Brewfile. ==="
