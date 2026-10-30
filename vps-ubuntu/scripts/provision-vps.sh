#!/usr/bin/env bash
# Qimono VPS convergence: Guix + reproducible CLI profile + native Stow shell.
# Run from the checked-out dotfiles repo: sudo ./vps-ubuntu/scripts/provision-vps.sh
set -Eeuo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REFRESH_GUIX=0
case "${1:-}" in
  "") ;;
  --refresh-guix) REFRESH_GUIX=1 ;;
  --help) echo "Usage: sudo bash $0 [--refresh-guix]"; exit 0 ;;
  *) echo "Unknown option: $1" >&2; exit 2 ;;
esac
REPO="$(cd "$ROOT/.." && pwd)"
TARGET_USER="${SUDO_USER:-root}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
[[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || { echo "Cannot resolve home for $TARGET_USER" >&2; exit 1; }
log(){ printf '\n\n========== %s ==========\n' "$*"; }
OPTIONAL_FAILURES=()
run_optional(){
  local label="$1"; shift
  log "$label"
  if "$@"; then
    echo "OPTIONAL STAGE OK: $label"
  else
    local rc=$?
    echo "WARNING: Optional stage '$label' failed (exit $rc). Continuing; no later stage depends on it." >&2
    OPTIONAL_FAILURES+=("$label (exit $rc)")
  fi
}
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

log "Authorize Nonguix substitutes and prepare Qimono Guix channels"
SUBSTITUTE_URLS="https://substitutes.nonguix.org https://bordeaux.guix.gnu.org https://ci.guix.gnu.org"
NONGUIX_KEY="$(mktemp)"
trap 'rm -f "$NONGUIX_KEY"' EXIT
curl -fsSL https://substitutes.nonguix.org/signing-key.pub -o "$NONGUIX_KEY"
guix archive --authorize < "$NONGUIX_KEY"
mkdir -p "$TARGET_HOME/.config/guix"
install -o "$TARGET_USER" -g "$(id -gn "$TARGET_USER")" -m 644 "$ROOT/guix/channels.scm" "$TARGET_HOME/.config/guix/channels.scm"
GUIX_CURRENT="$TARGET_HOME/.config/guix/current"
if [[ "$REFRESH_GUIX" -eq 1 || ! -x "$GUIX_CURRENT/bin/guix" ]]; then
  [[ "$REFRESH_GUIX" -eq 1 ]] && log "Explicit Guix refresh requested" || log "Initialize first Guix generation"
  as_target env PATH="$PATH" guix pull --channels="$TARGET_HOME/.config/guix/channels.scm" --substitute-urls="$SUBSTITUTE_URLS"
else
  log "Reuse existing Guix generation (no network pull)"
fi

log "Load the pulled Guix profile"
[[ -x "$GUIX_CURRENT/bin/guix" ]] || { echo "guix pull did not create $GUIX_CURRENT/bin/guix" >&2; exit 1; }
GUIX="$GUIX_CURRENT/bin/guix"
PROFILE="$TARGET_HOME/.guix-profile"
mkdir -p "$TARGET_HOME/.config"
chown -R "$TARGET_USER:$(id -gn "$TARGET_USER")" "$TARGET_HOME/.config/guix"
log "Apply complete Guix profile manifest"
if as_target "$GUIX" package --help >/dev/null 2>&1; then
  if ! as_target "$GUIX" package --manifest="$ROOT/guix/manifest.scm" --profile="$PROFILE" --substitute-urls="$SUBSTITUTE_URLS"; then
    echo "WARNING: Guix manifest application failed. Continuing with Ubuntu-managed shell and CLI setup." >&2
    GUIX_PROFILE_FAILED=1
    OPTIONAL_FAILURES+=("Guix user profile (manifest application)")
  else
    GUIX_PROFILE_FAILED=0
  fi
else
  echo "WARNING: Guix package command unavailable. Continuing with Ubuntu-managed shell and CLI setup." >&2
  GUIX_PROFILE_FAILED=1
  OPTIONAL_FAILURES+=("Guix command unavailable")
fi

run_optional "Install MongoDB Atlas CLI (mongosh intentionally omitted)" bash "$ROOT/scripts/install-mongodb-tools.sh"

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
run_optional "Apply VPS-native Stow shell package" as_target stow --dir="$STOW_SOURCE" --target="$TARGET_HOME" --restow shell

log "Set Zsh as root/target login shell"
ZSH_BIN="$(command -v zsh || true)"
[[ -x "$ZSH_BIN" ]] || { echo "zsh binary missing after apt installation." >&2; exit 1; }
grep -Fxq "$ZSH_BIN" /etc/shells || printf '%s\n' "$ZSH_BIN" >> /etc/shells
CURRENT_SHELL="$(getent passwd "$TARGET_USER" | cut -d: -f7)"
if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
  chsh -s "$ZSH_BIN" "$TARGET_USER"
fi

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
if [[ "${GUIX_PROFILE_FAILED:-0}" -eq 1 ]]; then
  echo "Provisioning completed with a Guix profile warning. Shell and host tooling were still configured."
else
  echo "Provisioning complete. Reconnect SSH to load the Stow-managed Zsh environment."
fi
printf 'Login shell: %s\\n' "$(getent passwd "$TARGET_USER" | cut -d: -f7)"
if (("${#OPTIONAL_FAILURES[@]}" > 0)); then
  echo "Optional stages with warnings:"
  printf ' - %s\\n' "${OPTIONAL_FAILURES[@]}"
else
  echo "Optional stages: all successful"
fi
