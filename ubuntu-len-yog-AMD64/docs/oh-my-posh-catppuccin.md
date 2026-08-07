# Oh My Posh + Catppuccin Theme + Cascaydia Cove Font Setup

This document details the installation, Stow symlinking, and theme configuration for **Oh My Posh** using the **Catppuccin** theme and the **Cascaydia Cove (CaskaydiaCove)** Nerd Font.

---

## 1. Overview & Repository Setup Analysis

Before applying this configuration, similar setups across this repository were searched and analyzed:

| Path / Machine Pack | Config / Theme Location | Zsh Integration |
|---|---|---|
| `ubuntu-len-yog-AMD64/stow-source/shell/` | `.config/oh-my-posh/catppuccin.omp.json` | `.zshrc` & `.zshrc.d/40-oh-my-posh.zsh` |
| `fedora/` | `fedora/config/oh-my-posh/catppuccin.omp.json` | `fedora/home/.zshrc` |
| `ubuntu/` | `ubuntu/.config/oh-my-posh/catppuccin.omp.json` | `ubuntu/install-curl-apps.sh` |
| `gnu-guix/` | Online URL fetch in `gnu-guix/home/zshrc` | `catppuccin_mocha.omp.json` via GitHub |
| `zsh/` | `zsh/zshrc` | `eval "$(oh-my-posh init zsh ...)"` |

---

## 2. Installation via `curl`

### A. Installing Oh My Posh
`oh-my-posh` is installed/updated into `~/.local/bin` using the official curl installation script:

```bash
mkdir -p ~/.local/bin
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
```

### B. Installing Cascaydia Cove (CaskaydiaCove) Nerd Font
The font files (`CaskaydiaCoveNerdFont*.ttf`) are fetched via `curl` from the official Nerd Fonts repository releases and installed into user font directory `~/.local/share/fonts/NerdFonts`:

```bash
FONT_DIR="$HOME/.local/share/fonts/NerdFonts"
mkdir -p "$FONT_DIR"
TMP_ZIP="$(mktemp --suffix=.zip)"
curl -fLo "$TMP_ZIP" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip"
unzip -o "$TMP_ZIP" -d "$FONT_DIR"
rm -f "$TMP_ZIP"
fc-cache -fv "$FONT_DIR"
```

---

## 3. Symlinking `$HOME/.zshrc` with GNU Stow

To link `$HOME/.zshrc` and `$HOME/.config/oh-my-posh/catppuccin.omp.json` to the repo-managed stow tree without conflict:

1. **Backup existing non-symlinked file**:
   If `$HOME/.zshrc` exists as a regular file, Stow will refuse to overwrite it to prevent loss. Move it to `$HOME/.zshrc.bak`:
   ```bash
   [[ -f "$HOME/.zshrc" && ! -L "$HOME/.zshrc" ]] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
   ```

2. **Apply Stow Symlinks**:
   ```bash
   cd ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64
   ./scripts/stow-apply.sh
   ```

3. **Resulting Symlinks in `$HOME`**:
   - `~/.zshrc` → `source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64/stow-source/shell/.zshrc`
   - `~/.config/oh-my-posh/catppuccin.omp.json` → `../../source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64/stow-source/shell/.config/oh-my-posh/catppuccin.omp.json`
   - `~/.zshrc.d/40-oh-my-posh.zsh` → `../source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64/stow-source/shell/.zshrc.d/40-oh-my-posh.zsh`

---

## 4. Shell Integration & Verification

In `~/.zshrc` (or via `.zshrc.d/40-oh-my-posh.zsh`):

```zsh
if command -v oh-my-posh >/dev/null 2>&1; then
  if [[ -f "$HOME/.config/oh-my-posh/catppuccin.omp.json" ]]; then
    eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/catppuccin.omp.json")"
  else
    eval "$(oh-my-posh init zsh)"
  fi
fi
```

### Verification Command
Run the following to verify prompt generation:

```bash
zsh -c 'source ~/.zshrc && oh-my-posh print primary'
```

Output:
```text
 qi@qimono-localhost ~/..../dotfiles  main
```
