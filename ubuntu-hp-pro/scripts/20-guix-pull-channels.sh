#!/usr/bin/env bash
# Install channels.scm and guix pull so firefox exists as a package.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANNELS_SRC="$ROOT/guix/channels.scm"

mkdir -p "$HOME/.config/guix"
cp -f "$CHANNELS_SRC" "$HOME/.config/guix/channels.scm"
echo "Installed ~/.config/guix/channels.scm (nonguix)"

# Prefer whatever guix is available (pre-pull)
export PATH="/usr/local/bin:${PATH:-}"
hash -r 2>/dev/null || true

if ! command -v guix >/dev/null 2>&1; then
  echo "error: guix not found; run 10-install-guix.sh first" >&2
  exit 1
fi

echo "==> guix pull (can take many minutes; needs network)…"
guix pull

# Activate post-pull guix for this process
if [[ -d "$HOME/.config/guix/current/bin" ]]; then
  export PATH="$HOME/.config/guix/current/bin:$PATH"
  hash -r
fi

echo "using: $(command -v guix)"
guix describe | head -20

# Hard gate: must be post-pull guix (has nonguix after channels pull)
if [[ "$(command -v guix)" != *'/.config/guix/current/bin/guix' ]]; then
  echo "error: not using post-pull guix at ~/.config/guix/current/bin/guix" >&2
  echo "       got: $(command -v guix)" >&2
  echo "       fix: export PATH=\"\$HOME/.config/guix/current/bin:\$PATH\" && hash guix" >&2
  exit 1
fi

if ! guix show firefox >/dev/null 2>&1; then
  echo "error: firefox still unknown after pull — check channels.scm / network" >&2
  exit 1
fi
echo "OK: firefox package visible via post-pull guix"

# --- qimono: persisted Guix profile via manifest (single source of truth) ---
# Persisted in guix/profile-manifest.scm so a fresh machine reproduces the
# whole profile: firefox, epiphany, jupyter, and vscodium (patched). CAUTION:
# `guix package --manifest` REPLACES the profile with exactly the manifest
# contents — keep every Guix-installed package in profile-manifest.scm.
# vscodium is #:substitutable? #f in nonguix (no substitutes), but its build
# only repackages the prebuilt GitHub release tarball — fast, no compilation.
# Idempotent: skips if vscodium already installed.
MANIFEST_SRC="$ROOT/guix/profile-manifest.scm"
# nonguix packages (firefox) need substitutes.nonguix.org — not in the default
# server list — else the install falls back to a source build.
SUBST_URLS='https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org'
if guix package -I 2>/dev/null | grep -qE '^vscodium([[:space:]]|$)'; then
  echo "OK: vscodium already installed"
else
  echo "==> guix package --manifest=$MANIFEST_SRC"
  guix package --manifest="$MANIFEST_SRC" --substitute-urls="$SUBST_URLS"
  echo "OK: profile installed (see ~/.guix-profile/bin/{firefox,codium})"
fi
