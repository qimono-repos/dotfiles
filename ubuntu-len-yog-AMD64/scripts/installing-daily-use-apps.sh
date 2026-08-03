#!/usr/bin/env bash
# installing-daily-use-apps.sh
#
# LAST RESORT path for Guix userland packages.
# Preferred:  guix package -m guix/manifests/profile-full.scm
#   (one generation = full desired set; never a partial -m alone)
#
# This script uses `guix install` so each package is *added* to the current
# profile without wiping the rest — useful when you only need one missing app
# or when you are recovering after a bad slim manifest.
#
# Usage:
#   ./scripts/installing-daily-use-apps.sh           # all groups below
#   ./scripts/installing-daily-use-apps.sh core      # editors + CLI + python/uv/stow
#   ./scripts/installing-daily-use-apps.sh rust
#   ./scripts/installing-daily-use-apps.sh desktop   # kdeconnect + epiphany
#   ./scripts/installing-daily-use-apps.sh diagrams  # graphviz plantuml (optional)
#   ./scripts/installing-daily-use-apps.sh heavy     # ungoogled-chromium (large)
#
# After any install:
#   GUIX_PROFILE="$HOME/.guix-profile"
#   source "$GUIX_PROFILE/etc/profile"

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST_PREFERRED="$ROOT/guix/manifests/profile-full.scm"

if ! command -v guix >/dev/null 2>&1; then
  echo "error: guix not on PATH. Install Guix first (install-guix-ready.sh)." >&2
  exit 1
fi

echo "============================================================"
echo " PREFERRED workflow (not this script):"
echo "   guix package -m $MANIFEST_PREFERRED"
echo " This script is LAST RESORT additive installs via guix install."
echo "============================================================"
echo

need_profile() {
  export GUIX_PROFILE="${GUIX_PROFILE:-$HOME/.guix-profile}"
  if [[ -r "$GUIX_PROFILE/etc/profile" ]]; then
    # shellcheck disable=SC1091
    source "$GUIX_PROFILE/etc/profile"
  fi
}

install_group() {
  local title="$1"
  shift
  echo "==> $title"
  echo "    guix install $*"
  guix install "$@"
  echo
}

GROUP="${1:-all}"

case "$GROUP" in
  core)
    install_group "core: editors, CLI, python toolchain" \
      neovim emacs git ripgrep fd fzf tree htop openjdk \
      stow python uv glibc-locales pkg-config openssl zlib
    ;;
  rust)
    install_group "rust: compiler + cargo" \
      rust rust:cargo pkg-config openssl zlib
    ;;
  desktop)
    install_group "desktop: phone link + GNOME Web" \
      kdeconnect epiphany
    ;;
  diagrams)
    install_group "diagrams: graphviz + plantuml" \
      graphviz plantuml
    ;;
  heavy)
    echo "NOTE: ungoogled-chromium is large (download + disk + RAM)."
    install_group "heavy browsers" \
      ungoogled-chromium
    ;;
  all)
    install_group "core: editors, CLI, python toolchain" \
      neovim emacs git ripgrep fd fzf tree htop openjdk \
      stow python uv glibc-locales pkg-config openssl zlib
    install_group "rust: compiler + cargo" \
      rust rust:cargo
    install_group "desktop: phone link + GNOME Web" \
      kdeconnect epiphany
    echo "Skip 'diagrams' and 'heavy' unless you need them:"
    echo "  $0 diagrams"
    echo "  $0 heavy"
    ;;
  help|-h|--help)
    sed -n '1,35p' "$0"
    exit 0
    ;;
  *)
    echo "unknown group: $GROUP (use: all|core|rust|desktop|diagrams|heavy|help)" >&2
    exit 1
    ;;
esac

need_profile
echo "OK. Refresh shell:  source \"\${GUIX_PROFILE:-\$HOME/.guix-profile}/etc/profile\""
echo "List profile:       guix package -I"
echo "Still preferred:    guix package -m $MANIFEST_PREFERRED"
