#!/usr/bin/env bash
# Qimono VPS shell stack: PATH + Zsh + GNU Stow + Oh My Posh.
# Safe to run as root or a normal user with sudo.
# Does NOT touch Codex auth/config, OpenCode config, or providers.env.
set -Eeuo pipefail

HOME_DIR="${HOME:?HOME is not set}"
DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HP_SHELL="$DOTFILES_ROOT/ubuntu-hp-pro/stow-source/shell"
MARK_BEGIN="# >>> qimono vps shell stack >>>"
MARK_END="# <<< qimono vps shell stack <<<"
DRY_RUN=0
NO_PROMPT=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --yes) NO_PROMPT=1 ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [--yes]"
      echo "Installs zsh, stow, Oh My Posh, links the Qimono Catppuccin Zsh prompt,"
      echo "and sets Zsh as the account's default login shell."
      exit 0
      ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

log() { printf '\n==> %s\n' "$*"; }
run() {
  if (( DRY_RUN )); then printf 'PLAN: '; printf '%q ' "$@"; printf '\n'
  else "$@"; fi
}
as_root() {
  if [[ $EUID -eq 0 ]]; then run "$@"
  elif command -v sudo >/dev/null 2>&1; then run sudo "$@"
  else echo "Need root or sudo to run: $*" >&2; exit 1
  fi
}
backup_path() {
  local path="$1"
  if [[ -e "$path" || -L "$path" ]]; then
    local stamp backup
    stamp="$(date +%Y%m%dT%H%M%S)"
    backup="${path}.pre-qimono-${stamp}"
    log "Backing up $path -> $backup"
    run cp -a -- "$path" "$backup"
  fi
}
write_managed_block() {
  local file="$1" tmp
  tmp="$(mktemp)"
  if [[ -f "$file" ]]; then
    awk -v b="$MARK_BEGIN" -v e="$MARK_END" '
      $0==b {skip=1; next}
      $0==e {skip=0; next}
      !skip {print}
    ' "$file" > "$tmp"
  fi
  {
    [[ ! -s "$tmp" ]] || printf '\n'
    printf '%s\n' "$MARK_BEGIN"
    printf '%s\n' 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac'
    printf '%s\n' 'case ":$PATH:" in *":$HOME/.opencode/bin:"*) ;; *) PATH="$HOME/.opencode/bin:$PATH" ;; esac'
    printf '%s\n' 'export PATH'
    printf '%s\n' "$MARK_END"
  } >> "$tmp"
  if (( DRY_RUN )); then
    echo "PLAN: update managed PATH block in $file"
  else
    if [[ ! -e "$file" ]]; then install -m 644 /dev/null "$file"; fi
    cat "$tmp" > "$file"
    chmod 644 "$file"
    echo "Updated PATH block: $file"
  fi
  rm -f "$tmp"
}

log "Preflight"
[[ -d "$HP_SHELL" ]] || { echo "Missing canonical HP Pro shell pack: $HP_SHELL" >&2; exit 1; }
[[ -f "$HP_SHELL/.zshrc.d/40-oh-my-posh.zsh" ]] || { echo "Missing Oh My Posh Zsh config in source pack" >&2; exit 1; }
[[ -f "$HP_SHELL/.config/oh-my-posh/catppuccin.omp.json" ]] || { echo "Missing Catppuccin theme in source pack" >&2; exit 1; }
printf 'Home: %s\nDotfiles: %s\n' "$HOME_DIR" "$DOTFILES_ROOT"
printf 'Codex binary: '; [[ -x "$HOME_DIR/.local/bin/codex" ]] && echo present || echo not-found
printf 'OpenCode binary: '; [[ -x "$HOME_DIR/.opencode/bin/opencode" ]] && echo present || echo not-found

log "Install packages"
as_root apt-get update
as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y zsh stow curl ca-certificates

log "Install Oh My Posh"
if command -v oh-my-posh >/dev/null 2>&1 || [[ -x "$HOME_DIR/.local/bin/oh-my-posh" ]]; then
  echo "Oh My Posh already installed; leaving it in place."
else
  if (( DRY_RUN )); then
    echo "PLAN: download and install latest Oh My Posh to $HOME_DIR/.local/bin/oh-my-posh"
  else
    mkdir -p "$HOME_DIR/.local/bin"
    tmp="$(mktemp)"
    trap 'rm -f "${tmp:-}"' EXIT
    curl -fsSL https://ohmyposh.dev/install.sh -o "$tmp"
    bash "$tmp" -d "$HOME_DIR/.local/bin"
    rm -f "$tmp"
    trap - EXIT
  fi
fi

log "Prepare Zsh home"
mkdir -p "$HOME_DIR/.zshrc.d" "$HOME_DIR/.config/oh-my-posh"

# Do not adopt the complete desktop pack. Link only its portable shell pieces.
for rel in .zshrc.d/15-history.zsh .zshrc.d/20-aliases.zsh .zshrc.d/40-oh-my-posh.zsh .config/oh-my-posh/catppuccin.omp.json; do
  src="$HP_SHELL/$rel"
  dest="$HOME_DIR/$rel"
  [[ -e "$src" ]] || continue
  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "Already linked: $dest"
    continue
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    backup_path "$dest"
    if (( ! DRY_RUN )); then rm -rf -- "$dest"; fi
  fi
  if (( DRY_RUN )); then echo "PLAN: symlink $dest -> $src"
  else ln -s "$src" "$dest"; echo "Linked: $dest"; fi
done

log "Configure minimal Zsh startup"
ZSHRC="$HOME_DIR/.zshrc"
if [[ -e "$ZSHRC" || -L "$ZSHRC" ]]; then
  if ! grep -qF "$MARK_BEGIN" "$ZSHRC" 2>/dev/null; then
    backup_path "$ZSHRC"
  fi
fi
if (( DRY_RUN )); then
  echo "PLAN: create/update $ZSHRC to load ~/.zshrc.d/*.zsh and prepend CLI paths"
else
  cat > "$ZSHRC" <<'ZSHRC_EOF'
# Qimono VPS interactive Zsh configuration.
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$PATH" ;; esac
case ":$PATH:" in *":$HOME/.opencode/bin:"*) ;; *) PATH="$HOME/.opencode/bin:$PATH" ;; esac
export PATH
for _qimono_zsh_file in "$HOME"/.zshrc.d/*.zsh; do
  [[ -r "$_qimono_zsh_file" ]] && source "$_qimono_zsh_file"
done
unset _qimono_zsh_file
ZSHRC_EOF
  chmod 644 "$ZSHRC"
fi

log "Configure Bash and login PATH"
write_managed_block "$HOME_DIR/.bashrc"
write_managed_block "$HOME_DIR/.profile"

log "Set Zsh as the default login shell"
ZSH_BIN="$(command -v zsh || true)"
[[ -n "$ZSH_BIN" && -x "$ZSH_BIN" ]] || { echo "zsh executable not found after installation" >&2; exit 1; }
if ! grep -Fxq "$ZSH_BIN" /etc/shells; then
  if (( DRY_RUN )); then
    echo "PLAN: register $ZSH_BIN in /etc/shells"
  else
    printf '%s\n' "$ZSH_BIN" >> /etc/shells
  fi
fi
CURRENT_LOGIN_SHELL="$(getent passwd "$(id -un)" | cut -d: -f7)"
if [[ "$CURRENT_LOGIN_SHELL" == "$ZSH_BIN" ]]; then
  echo "Default login shell already set to $ZSH_BIN"
elif (( DRY_RUN )); then
  echo "PLAN: chsh -s $ZSH_BIN $(id -un)"
else
  if [[ $EUID -eq 0 ]]; then
    chsh -s "$ZSH_BIN" "$(id -un)"
  elif command -v sudo >/dev/null 2>&1; then
    sudo chsh -s "$ZSH_BIN" "$(id -un)"
  else
    echo "Cannot change login shell: run chsh -s $ZSH_BIN $(id -un)" >&2
    exit 1
  fi
  echo "Default login shell changed to $ZSH_BIN"
fi

log "Stow validation"
if (( ! DRY_RUN )); then
  stow --version | head -n 1
  zsh --version
  "$HOME_DIR/.local/bin/oh-my-posh" version 2>/dev/null || oh-my-posh version
  echo
  echo "Installed commands:"
  for bin in "$HOME_DIR/.local/bin/codex" "$HOME_DIR/.opencode/bin/opencode" "$HOME_DIR/.local/bin/oh-my-posh"; do
    [[ -x "$bin" ]] && printf '  %s\n' "$bin"
  done
fi

log "Complete"
echo "Open a new SSH session, or run: exec zsh"
echo "Verify: command -v codex; command -v opencode; command -v oh-my-posh"
echo "Default login shell: $(getent passwd "$(id -un)" | cut -d: -f7)"
echo "Reconnect over SSH to start directly in Zsh."
echo "Nerd Font note: install CascadiaCode Nerd Font on your LOCAL terminal computer for prompt glyphs."
