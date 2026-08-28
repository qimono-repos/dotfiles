#!/usr/bin/env bash
# Install/update oh-my-posh prompt for ubuntu-len-yog-ARM64, Catppuccin theme.
#
# Differs from the hp-pro sibling script:
#   * Font (Caskaydia Cove Nerd Font) is NOT re-downloaded via curl here — it is
#     owned by the Guix profile (`font-nerd-caskaydia` from base.scm), per this
#     pack's Guix-first policy and LESSONS-guix-browsers-type guidance.
#   * ~/.zshrc, ~/.zshrc.local, ~/.zshrc.d/*, ~/.config/oh-my-posh/* are all
#     stow-managed (stow-source/shell), NOT hand-written here. So we only:
#       1) ensure the binary is on PATH (~/.local/bin),
#       2) verify the stowed config + prompt init link resolve.
#
# Idempotent; safe to re-run anywhere (no sudo required).
# Usage: ./install-oh-my-posh.sh [--dry-run]
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) echo "usage: $0 [--dry-run]"; exit 0 ;;
    *) echo "unknown arg: $arg" >&2; exit 2 ;;
  esac
done

ok()  { printf '  %-42s OK    %s\n' "$1" "$2"; }
bad() { printf '  %-42s MISS  %s\n' "$1" "$2"; }
warn(){ printf '  %-42s WAIT  %s\n' "$1" "$2"; }
plan(){ printf '  %-42s PLAN  %s\n' "$1" "$2"; }

BIN="$HOME/.local/bin"
OMP="$BIN/oh-my-posh"
CFG_LINK="$HOME/.config/oh-my-posh/catppuccin.omp.json"
HOOK_LINK="$HOME/.zshrc.d/40-oh-my-posh.zsh"

echo "=== [ubuntu-len-yog-ARM64] oh-my-posh + Catppuccin (stow-managed) ==="

# ---- probes ----
INSTALLED=0
[[ -x "$OMP" ]] && INSTALLED=1

if (( INSTALLED )); then
  ok "oh-my-posh binary" "v$("$OMP" --version 2>/dev/null) at $OMP"
else
  bad "oh-my-posh binary" "not installed at $OMP"
fi

CFG_OK=0; [[ -L "$CFG_LINK" && -f "$CFG_LINK" ]] && CFG_OK=1
if (( CFG_OK )); then
  ok "catppuccin theme" "linked: $CFG_LINK"
else
  bad "catppuccin theme" "expected stow symlink missing"
fi

HOOK_OK=0; [[ -L "$HOOK_LINK" && -f "$HOOK_LINK" ]] && HOOK_OK=1
if (( HOOK_OK )); then
  ok "prompt init hook" "linked: .zshrc.d/40-oh-my-posh.zsh"
else
  bad "prompt init hook" "expected stow symlink missing"
fi

OMP_ENV_OK=0
if [[ -r "$HOME/.config/oh-my-posh/catppuccin.omp.json" ]]; then
  if command -v "$OMP" >/dev/null 2>&1 || [[ -x "$OMP" ]]; then
    OMP_ENV_OK=1
  fi
fi

if (( INSTALLED && CFG_OK && HOOK_OK )); then
  echo
  echo "All present. Restart shell (or: source ~/.zshrc) to render the prompt."
  echo "Verify: oh-my-posh print primary --shell zsh --config $CFG_LINK"
  exit 0
fi

if (( DRY_RUN )); then
  plan "install oh-my-posh" "./install-oh-my-posh.sh  (needs curl, no sudo)"
  exit 0
fi

# ---- install binary (official installer into ~/.local/bin) ----
if ! (( INSTALLED )); then
  if ! command -v curl >/dev/null 2>&1; then
    echo "error: curl is required" >&2
    exit 1
  fi
  mkdir -p "$BIN"
  echo "==> Installing oh-my-posh to $BIN (official installer)..."
  if ! curl -s https://ohmyposh.dev/install.sh | bash -s -- -d "$BIN"; then
    echo "error: oh-my-posh install failed" >&2
    exit 1
  fi
fi

# Re-probe and report
if [[ -x "$OMP" ]]; then
  ok "oh-my-posh binary" "v$("$OMP" --version 2>/dev/null)"
fi
[[ -L "$CFG_LINK" && -f "$CFG_LINK" ]] && ok "catppuccin theme" "linked" || warn "catppuccin theme" "restow shell: scripts/stow-apply.sh"
[[ -L "$HOOK_LINK" && -f "$HOOK_LINK" ]] && ok "prompt init hook" "linked"    || warn "prompt init hook" "restow shell: scripts/stow-apply.sh"

echo
echo "Done. Open a new shell (or: source ~/.zshrc) to activate the prompt."
echo "Verify: oh-my-posh print primary --shell zsh --config $CFG_LINK"
