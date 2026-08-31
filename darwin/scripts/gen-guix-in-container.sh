#!/usr/bin/env bash
# gen-guix-in-container.sh — write the guest-side Guix bootstrap scripts into
# $HOME/.qimono/ as TWO scripts (inside the container machine $HOME is the SAME
# path via VirtioFS mirroring, so they are already present in Linux):
#
#   ~/.qimono/guix-system-install.sh   # root: apt prereqs + guix-install.sh
#   ~/.qimono/guix-user-bootstrap.sh   # user: guix pull + manifest apply
#
# model: darwin/docs/guix-in-container.md. Idempotent at both levels.
# Usage: ./gen-guix-in-container.sh  (host side, macOS)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUIDIR="$(cd "$SCRIPT_DIR/../guix" && pwd)"
QDIR="$HOME/.qimono"
mkdir -p "$QDIR"

ok()  { printf '  %-42s OK    %s\n' "$1" "$2"; }
bad() { printf '  %-42s MISS  %s\n' "$1" "$2"; }

CHANNELS_PATH="$HOME/source/repos/qimono-repos/dotfiles/darwin/guix/channels.scm"
MANIFEST_PATH="$HOME/source/repos/qimono-repos/dotfiles/darwin/guix/manifests/darwin-base.scm"
[[ -f "$GUIDIR/channels.scm" ]] && ok "channels" "bundled at darwin/guix/channels.scm"
[[ -f "$GUIDIR/manifests/darwin-base.scm" ]] && ok "manifest" "bundled at darwin/guix/manifests/darwin-base.scm"

# ---- guest script 1: SYSTEM install (run as root) ---------------------------
cat > "$QDIR/guix-system-install.sh" <<'EOF'
#!/usr/bin/env bash
# Qimono — Guix SYSTEM install inside the Apple container machine (Debian).
# Run as ROOT:   sudo bash ~/.qimono/guix-system-install.sh
# Idempotent: skips if `guix` binary already on /usr/local/bin.
set -euo pipefail

if [[ "$(id -u)" != "0" ]]; then
  echo "error: run as root:  sudo bash $0" >&2
  exit 1
fi
if [[ "$(uname -s)" != "Linux" ]]; then
  echo "error: this script runs INSIDE the container machine (Linux), not on macOS." >&2
  exit 1
fi

echo "=== Guix SYSTEM install (Debian/container-machine) ==="

# systemd as PID 1 is the container-machine contract
if [[ "$(ps -p 1 -o comm= 2>/dev/null || true)" != "systemd" ]]; then
  echo "!! warning: PID 1 is not systemd — this machine base may be invalid." >&2
fi

if [[ -x /usr/local/bin/guix ]]; then
  echo "guix already installed: $(/usr/local/bin/guix --version | head -1)"
else
  echo "--- apt prereqs ---"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends \
    curl wget gzip bzip2 xz-utils tar unzip binutils \
    openssl ca-certificates locales sudo
  if ! grep -q '^en_US.UTF-8' /etc/locale.gen 2>/dev/null; then
    sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen; locale-gen || true
  fi

  echo "--- download + run official guix-install.sh ---"
  TMP="$(mktemp -d)"
  if ! wget -q -O "$TMP/guix-install.sh" \
      https://git.savannah.gnu.org/cgit/guix.git/plain/etc/guix-install.sh; then
    echo "download failed." >&2
  fi
  if ! head -1 "$TMP/guix-install.sh" 2>/dev/null | grep -q 'bash\|sh'; then
    echo "error: guix-install.sh did not fetch (offline? mirror?). Manual fallback:" >&2
    echo "  1) sudo tar --warning=no-timestamp -xf guix-binary-1.5.0.aarch64-linux.tar.xz -C /" >&2
    echo "  2) run the Guix manual 'Binary Installation' steps (build users, keys, daemon)." >&2
    rm -rf "$TMP"
    exit 1
  fi
  # </dev/null = take upstream defaults; the script refuses (non-fatal) if declined.
  bash "$TMP/guix-install.sh" </dev/null || \
    echo "!! guix-install.sh returned non-zero — inspect output above." >&2
  rm -rf "$TMP"
fi

echo
echo "System layer done. Verify:"
echo "  guix --version"
echo "Then, as your NORMAL user (qi), run:"
echo "  bash ~/.qimono/guix-user-bootstrap.sh"
EOF
chmod +x "$QDIR/guix-system-install.sh"
ok "guix-system-install.sh" "written → $QDIR/guix-system-install.sh"

# ---- guest script 2: USER bootstrap (run as normal user) ---------------------
cat > "$QDIR/guix-user-bootstrap.sh" <<'EOF'
#!/usr/bin/env bash
# Qimono — Guix USER bootstrap inside the Apple container machine (Debian).
# Run as the normal user (NOT root):   bash ~/.qimono/guix-user-bootstrap.sh
# Idempotent: `guix pull` is cheap to re-run; manifest re-apply is safe.
set -euo pipefail

if [[ "$(id -u)" == "0" ]]; then
  echo "error: run as normal user, not root (use: bash $0)" >&2
  exit 1
fi
command -v guix >/dev/null 2>&1 || { echo "error: guix not on PATH — run the SYSTEM install first." >&2; exit 1; }

DOTFILES="$HOME/source/repos/qimono-repos/dotfiles"
CHANNELS="$DOTFILES/darwin/guix/channels.scm"
MANIFEST="$DOTFILES/darwin/guix/manifests/darwin-base.scm"
for f in "$CHANNELS" "$MANIFEST"; do
  [[ -f "$f" ]] || { echo "error: missing $f (is the dotfiles repo cloned in \$HOME?)." >&2; exit 1; }
done

echo "=== Guix USER bootstrap ==="
echo "--- guix pull (channels: nonguix + defaults) ---"
guix pull --channels="$CHANNELS"

echo "--- guix package -m darwin-base.scm ---"
guix package -m "$MANIFEST"

echo "--- enable profile in this shell ---"
export GUIX_PROFILE="$HOME/.guix-profile"
source "$HOME/.guix-profile/etc/profile"

echo
echo "Done. Verify:"
echo "  guix --version"
echo "  guix package -I | head"
echo "  guix shell hello -- hello"
echo "(new shells auto-source the OS-guarded ~/.zshrc.d/05-guix.zsh)"
EOF
chmod +x "$QDIR/guix-user-bootstrap.sh"
ok "guix-user-bootstrap.sh" "written → $QDIR/guix-user-bootstrap.sh"

echo
cat <<'OIE'
Next steps:
  1) container machine run qi-dev
  2) sudo bash ~/.qimono/guix-system-install.sh     # root: system layer
  3) bash ~/.qimono/guix-user-bootstrap.sh          # user: profile layer
OIE