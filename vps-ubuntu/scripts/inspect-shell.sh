#!/usr/bin/env bash
# Qimono VPS shell inspection
# Read-only diagnostic for shell, PATH, Codex/OpenCode, Stow and Oh My Posh.
# Does not print environment values, API keys, tokens, or config file contents.
set -uo pipefail

HOME_DIR="${HOME:-/root}"
DOTFILES="${DOTFILES_DIR:-$HOME_DIR/source/repos/qimono-repos/dotfiles}"
HP_PACK="$DOTFILES/ubuntu-hp-pro/stow-source/shell"
VPS_PACK="$DOTFILES/vps-ubuntu"

section() { printf '\n=== %s ===\n' "$1"; }
row() { printf '%-24s %s\n' "$1" "$2"; }
resolve() {
  local name="$1" path=""
  path="$(command -v "$name" 2>/dev/null || true)"
  if [[ -n "$path" ]]; then
    printf '%s' "$path"
  elif [[ -x "$HOME_DIR/.local/bin/$name" ]]; then
    printf '%s (absolute path; not on PATH)' "$HOME_DIR/.local/bin/$name"
  elif [[ "$name" == opencode && -x "$HOME_DIR/.opencode/bin/opencode" ]]; then
    printf '%s (absolute path; not on PATH)' "$HOME_DIR/.opencode/bin/opencode"
  else
    printf 'not found'
  fi
}

section "HOST"
row "hostname" "$(hostname 2>/dev/null || printf unknown)"
row "user" "$(id -un 2>/dev/null || printf unknown)"
row "home" "$HOME_DIR"
row "OS" "$(. /etc/os-release 2>/dev/null; printf '%s %s' "${PRETTY_NAME:-unknown}" "${VERSION_CODENAME:-}")"

section "SHELL"
row "login shell (passwd)" "$(getent passwd "$(id -u)" 2>/dev/null | awk -F: '{print $7}' || true)"
row "SHELL variable" "${SHELL:-unset}"
row "current process" "$(ps -p $$ -o comm= 2>/dev/null | xargs || true)"
row "bash" "$(resolve bash)"
row "zsh" "$(resolve zsh)"
row "stow" "$(resolve stow)"
row "oh-my-posh" "$(resolve oh-my-posh)"
row "codex" "$(resolve codex)"
row "opencode" "$(resolve opencode)"

section "PATH"
printf '%s\n' "${PATH:-unset}" | tr ':' '\n' | nl -ba
printf '\n'
for dir in "$HOME_DIR/.local/bin" "$HOME_DIR/.opencode/bin" "$HOME_DIR/bin" /usr/local/bin /usr/bin; do
  if [[ -d "$dir" ]]; then
    case ":$PATH:" in
      *":$dir:"*) row "$dir" "present on PATH" ;;
      *) row "$dir" "exists, NOT on PATH" ;;
    esac
  else
    row "$dir" "directory absent"
  fi
done

section "CLI BINARIES"
for file in "$HOME_DIR/.local/bin/codex" "$HOME_DIR/.opencode/bin/opencode" "$HOME_DIR/.local/bin/oh-my-posh"; do
  if [[ -x "$file" ]]; then
    row "$file" "executable"
    case "$file" in
      */codex) "$file" --version 2>&1 | head -1 | sed 's/^/  version: /' ;;
      */opencode) "$file" --version 2>&1 | head -1 | sed 's/^/  version: /' ;;
      */oh-my-posh) "$file" version 2>&1 | head -1 | sed 's/^/  version: /' ;;
    esac
  else
    row "$file" "missing"
  fi
done

section "SHELL CONFIG FILES"
for file in .bashrc .bash_profile .profile .zshenv .zprofile .zshrc .zlogin .zshrc.local; do
  path="$HOME_DIR/$file"
  if [[ -e "$path" || -L "$path" ]]; then
    if [[ -L "$path" ]]; then
      row "$file" "symlink -> $(readlink "$path")"
    else
      row "$file" "regular file ($(stat -c '%a' "$path" 2>/dev/null || printf '?') permissions)"
    fi
  else
    row "$file" "absent"
  fi
done

section "ZSH CONFIG TREE"
if [[ -d "$HOME_DIR/.zshrc.d" ]]; then
  find "$HOME_DIR/.zshrc.d" -maxdepth 2 \( -type f -o -type l \) -printf '%y %p -> %l\n' | sort
else
  printf 'No ~/.zshrc.d directory\n'
fi

section "DOTFILES PACKS"
row "dotfiles repo" "$([[ -d "$DOTFILES/.git" ]] && printf present || printf missing): $DOTFILES"
row "VPS pack" "$([[ -d "$VPS_PACK" ]] && printf present || printf missing)"
row "HP Pro shell pack" "$([[ -d "$HP_PACK" ]] && printf present || printf missing)"
if [[ -d "$HP_PACK" ]]; then
  find "$HP_PACK" -maxdepth 4 \( -type f -o -type l \) -printf '%y %P -> %l\n' | sort
fi

section "STOW LINKS"
for path in "$HOME_DIR/.zshrc" "$HOME_DIR/.zshrc.d" "$HOME_DIR/.config/oh-my-posh/catppuccin.omp.json"; do
  if [[ -L "$path" ]]; then
    row "$path" "symlink -> $(readlink "$path")"
  elif [[ -e "$path" ]]; then
    row "$path" "exists, not a symlink"
  else
    row "$path" "absent"
  fi
done

section "INSTALLED PACKAGES"
for pkg in zsh stow fonts-cascadia-code; do
  if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed'; then
    row "$pkg" "installed via dpkg"
  else
    row "$pkg" "not installed via dpkg"
  fi
done

section "PROMPT THEME"
theme="$HOME_DIR/.config/oh-my-posh/catppuccin.omp.json"
if [[ -r "$theme" ]]; then
  row "Catppuccin theme" "present and readable"
else
  row "Catppuccin theme" "missing"
fi
font_dir="$HOME_DIR/.local/share/fonts/NerdFonts"
if [[ -d "$font_dir" ]]; then
  row "Nerd Fonts directory" "present"
  find "$font_dir" -maxdepth 1 -type f \( -iname '*.ttf' -o -iname '*.otf' \) -printf '  %f\n' | head -10
else
  row "Nerd Fonts directory" "absent"
fi

section "DONE"
printf 'Read-only inspection complete. No files were changed.\n'
