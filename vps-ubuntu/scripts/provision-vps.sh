#!/usr/bin/env bash
# Qimono VPS convergence: Guix + reproducible CLI profile + native Stow shell.
# Run from the checked-out dotfiles repo: sudo ./vps-ubuntu/scripts/provision-vps.sh
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO="$(cd "$ROOT/.." && pwd)"
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || { echo "Cannot resolve home for $TARGET_USER" >&2; exit 1; }
log(){ printf '\n\n========== %s ==========\n' "$*"; }
as_target(){ if [[ "$TARGET_USER" == root ]]; then "$@"; else sudo -u "$TARGET_USER" -H "$@"; fi; }

[[ "$(uname -m)" == x86_64 ]] || { echo "This VPS profile currently targets x86_64." >&2; exit 1; }
[[ -f "$ROOT/guix/manifest.scm" && -f "$ROOT/guix/channels.scm" ]] || { echo "Run from a complete dotfiles checkout." >&2; exit 1; }

log "Host prerequisites"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y ca-certificates curl git gnupg stow tar unzip wget xz-utils zsh

log "GNU Guix installation"
if ! command -v guix >/dev/null 2>&1; then
  bash "$ROOT/scripts/install-guix.sh"
fi
if ! command -v guix >/dev/null 2>&1; then
  for p in /var/guix/profiles/per-user/root/current-guix/bin /usr/local/bin; do
    [[ -x "$p/guix" ]] && export PATH="$p:$PATH"
  done
fi
command -v guix >/dev/null 2>&1 || { echo "Guix command unavailable after install." >&2; exit 1; }

log "Refresh official Guix channel"
mkdir -p "$TARGET_HOME/.config/guix"
install -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" -m 644 "$ROOT/guix/channels.scm" "$TARGET_HOME/.config/guix/channels.scm"
as_target env PATH="$PATH" guix pull --channels="$TARGET_HOME/.config/guix/channels.scm"

log "Load the pulled Guix profile"
GUIX_CURRENT="$TARGET_HOME/.config/guix/current"
[[ -x "$GUIX_CURRENT/bin/guix" ]] || { echo "guix pull did not create $GUIX_CURRENT/bin/guix" >&2; exit 1; }
GUIX="$GUIX_CURRENT/bin/guix"
PROFILE="$TARGET_HOME/.guix-profile"
mkdir -p "$TARGET_HOME/.config"
chown -R "$TARGET_USER:$(id -gn "$TARGET_USER")" "$TARGET_HOME/.config/guix"
log "Apply complete Guix profile manifest"
as_target "$GUIX" package --manifest="$ROOT/guix/manifest.scm" --profile="$PROFILE"

log "Install MongoDB Atlas CLI and mongosh"
bash "$ROOT/scripts/install-mongodb-tools.sh"

log "Prepare VPS-native Stow package"
install -d -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" "$TARGET_HOME/.local/share/qimono"
# The checked-out repo remains the source of truth; Stow links from this pack.
STOW_SOURCE="$ROOT/stow-source"
[[ -d "$STOW_SOURCE/shell" ]] || { echo "Missing VPS shell Stow package." >&2; exit 1; }
# Remove only known legacy links from the earlier desktop-pack experiment.
for rel in .zshrc.d/15-history.zsh .zshrc.d/20-aliases.zsh .zshrc.d/40-oh-my-posh.zsh .config/oh-my-posh/catppuccin.omp.json; do
  dest="$TARGET_HOME/$rel"
  if [[ -L "$dest" ]] && readlink "$dest" | grep -q '/ubuntu-hp-pro/stow-source/shell/'; then rm "$dest"; fi
done
if [[ -e "$TARGET_HOME/.zshrc" && ! -L "$TARGET_HOME/.zshrc" ]] && ! grep -q 'QIMONO VPS STOW' "$TARGET_HOME/.zshrc"; then
  cp -a "$TARGET_HOME/.zshrc" "$TARGET_HOME/.zshrc.pre-vps-stow.$(date +%Y%m%dT%H%M%S)"
  rm "$TARGET_HOME/.zshrc"
fi
as_target stow --dir="$STOW_SOURCE" --target="$TARGET_HOME" --restow shell

log "Preserve existing LLM authentication"
# No provider/API key selection means Codex config and OAuth state are untouched.
if [[ -f "$TARGET_HOME/.codex/auth.json" ]]; then
  echo "Codex auth file exists; contents intentionally not inspected or printed."
fi
echo "LLM wiring is not run by this provisioner. Use configure-llm.sh only for explicit API-provider setup."

log "Machine report"
printf 'Host: %s\nArchitecture: %s\nTarget user: %s\n' "$(hostname)" "$(uname -m)" "$TARGET_USER"
printf 'Guix: '; as_target "$GUIX" --version | head -1
printf 'Guix profile: %s\n' "$PROFILE"
printf 'Java: '; java -version 2>&1 | head -1 || true
printf 'Zsh: '; zsh --version
printf 'Stow: '; stow --version | head -1
printf 'Codex: '; [[ -x "$TARGET_HOME/.local/bin/codex" ]] && "$TARGET_HOME/.local/bin/codex" --version | head -1 || echo "not installed"
printf 'OpenCode: '; [[ -x "$TARGET_HOME/.opencode/bin/opencode" ]] && "$TARGET_HOME/.opencode/bin/opencode" --version | head -1 || echo "not installed"
printf 'Disk: '; df -h / | awk 'NR==2 {print $4 " available of " $2}'
printf 'Memory: '; free -h | awk '/Mem:/ {print $7 " available of " $2}'
echo
echo "Provisioning complete. Reconnect SSH to load the Stow-managed Zsh environment."
