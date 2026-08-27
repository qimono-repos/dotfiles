#!/usr/bin/env bash
# Qimono fleet bootstrap — Linux/Ubuntu (Guix-first, strict).
#
# Flows (all idempotent):
#   1. apt-install minimal prereqs the bootstrap itself needs (curl git zsh tar).
#   2. Clone the PUBLIC dotfiles repo over HTTPS into ~/source/repos/qimono-repos/dotfiles
#      (no auth needed; the repo is public by design so a brand-new machine can fetch it).
#   3. Detect this machine's pack (arch + vendor/model map).
#   4. Guix-first (strict): run the pack's install-guix-binary.sh -> finish-guix-binary.sh
#      -> install-host-sysctl.sh, all via sudo.
#   5. Hand off to the pack's own bootstrap.sh (already idempotent).
#
# Run via the curl|sh entrypoint (fleet/install) on Linux.

set -euo pipefail

QIMONO_SRC="${QIMONO_SRC:-${HOME}/source/repos/qimono-repos}"
REPO_DIR="${QIMONO_SRC}/dotfiles"
REPO_URL="https://github.com/qimono-repos/dotfiles.git"
BRANCH="${BRANCH:-main}"

ok()   { printf '  %-40s OK    %s\n' "$1" "$2"; }
bad()  { printf '  %-40s MISS  %s\n' "$1" "$2"; }
warn() { printf '  %-40s WAIT  %s\n' "$1" "$2"; }

echo "=== guix.sh — Linux/Ubuntu Guix-first bootstrap on $(hostname) ==="
echo

# ---- 1. prerequisite system packages (apt) ---------------------------------
echo "--- checking prerequisites (curl git zsh tar) ---"
NEED_APT=()
for c in curl git zsh tar; do
  if command -v "$c" >/dev/null 2>&1; then
    ok "$c" "$(command -v "$c")"
  else
    bad "$c" "not installed"
    NEED_APT+=("$c")
  fi
done

if (( ${#NEED_APT[@]} )); then
  if command -v apt-get >/dev/null 2>&1; then
    echo "--- apt installing ${NEED_APT[*]} (sudo) ---"
    sudo apt-get update
    sudo apt-get install -y "${NEED_APT[@]}"
    for c in "${NEED_APT[@]}"; do
      command -v "$c" >/dev/null 2>&1 && ok "$c" "now on PATH" || warn "$c" "install claimed OK but not on PATH"
    done
  else
    echo "error: missing ${NEED_APT[*]} and this isn't apt-based (found no apt-get)." >&2
    echo "       Install them with your distro manager, then re-run." >&2
    exit 2
  fi
fi

# ---- 2. clone the public dotfiles repo (HTTPS, no auth) ---------------------
echo "--- fetching dotfiles repo (public, HTTPS) ---"
mkdir -p "${QIMONO_SRC}"
if [[ -d "$REPO_DIR/.git" ]]; then
  ok "dotfiles repo" "already present at ${REPO_DIR}"
  git -C "$REPO_DIR" fetch origin "${BRANCH}" >/dev/null 2>&1 || warn "fetch" "could not fetch ${BRANCH} (offline?)"
else
  git clone --branch "${BRANCH}" "${REPO_URL}" "$REPO_DIR"
  ok "dotfiles repo" "cloned to ${REPO_DIR}"
fi

# ---- 3. pack detection (arch + vendor/model) -------------------------------
echo "--- detecting machine pack ---"
ARCH="$(uname -m)"
VENDOR="$(cat /sys/class/dmi/id/sys_vendor 2>/dev/null || echo '')"
PRODUCT="$(cat /sys/class/dmi/id/product_name 2>/dev/null || echo '')"
PRODVER="$(cat /sys/class/dmi/id/product_version 2>/dev/null || echo '')"
# Match on a lowercased, concatenated identity string (vendor + product +
# product_version), since DMI layout varies (e.g. Yoga Slim 7 may expose the
# model/SKU as product_name and "Yoga Slim" as product_version).
IDLOWER="$(printf '%s %s %s\n' "$VENDOR" "$PRODUCT" "$PRODVER" | tr '[:upper:]' '[:lower:]')"
case "$IDLOWER" in
  *yoga*|*thinkpad*)
    if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then PACK="ubuntu-len-yog-ARM64";
    else PACK="ubuntu-len-yog-AMD64"; fi ;;
  *probook*)                       PACK="ubuntu-hp-pro" ;;
  *mini*pc*)                       PACK="ubuntu-mini-pc" ;;
  *)                               PACK="ubuntu" ;;
esac
ok "detected pack" "${PACK} (arch=${ARCH}, vendor=${VENDOR:-?}, model=${PRODUCT:-?}/${PRODVER:-?})"

PACK_DIR="$REPO_DIR/$PACK"
if [[ ! -d "$PACK_DIR" ]]; then
  warn "pack dir" "$PACK_DIR missing — falling back to generic ubuntu flow"
  PACK_DIR="$REPO_DIR/ubuntu"
fi

# ---- 4. Guix-first (strict): binary install (sudo) -------------------------
echo "--- Guix-first: binary install ---"
if command -v guix >/dev/null 2>&1; then
  ok "guix" "$(guix --version 2>/dev/null | head -1)"
else
  echo "Installing GNU Guix binary (needs sudo; prompts for password)."
  if [[ -x "$PACK_DIR/scripts/install-guix-binary.sh" ]] && [[ -x "$PACK_DIR/scripts/finish-guix-binary.sh" ]]; then
    TARBALL="/tmp/opencode/guix-binary-1.5.0.${ARCH}-linux.tar.xz"
    # Download if not already staged (ARM64 trap: tarball lacks /usr/local/bin/guix,
    # finish-guix-binary.sh repairs keys + daemon + symlink).
    if [[ ! -f "$TARBALL" ]]; then
      mkdir -p "$(dirname "$TARBALL")"
      echo "-- downloading Guix tarball (this can be large) --"
      curl -fSL -o "$TARBALL" "https://ftpmirror.gnu.org/gnu/guix/guix-binary-1.5.0.${ARCH}-linux.tar.xz" || true
    fi
    sudo bash "$PACK_DIR/scripts/install-guix-binary.sh"
    sudo bash "$PACK_DIR/scripts/finish-guix-binary.sh"
    ok "guix" "binary install completed"
    [[ -x "$PACK_DIR/scripts/install-host-sysctl.sh" ]] && sudo bash "$PACK_DIR/scripts/install-host-sysctl.sh"
  else
    warn "guix" "no per-pack guix scripts for ${PACK}; run the pack README manually"
  fi
fi

# ---- 5. hand off to the pack's bootstrap.sh ---------------------------------
if [[ -x "$PACK_DIR/scripts/bootstrap.sh" ]]; then
  echo "--- running pack bootstrap (${PACK}) ---"
  bash "$PACK_DIR/scripts/bootstrap.sh"
else
  echo "--- no pack bootstrap.sh; applying stow directly ---"
  ( cd "$PACK_DIR" && [[ -x ./scripts/stow-apply.sh ]] && ./scripts/stow-apply.sh ) || \
    warn "stow" "no stow-apply.sh for ${PACK}"
fi

echo
echo "=== guix.sh done. Open a new shell (or source ~/.zshrc). ==="
