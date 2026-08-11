# Stow usage (this pack)

[GNU Stow](https://www.gnu.org/software/stow/) manages **symlinks** from package trees into `$HOME`.

## Install stow

Prefer Guix (aspirational rank 1):

```bash
guix install stow
# ensure profile is on PATH (see stow-source/shell package)
```

Fallback apt only if Guix is unavailable:

```bash
sudo apt install stow
```

## Why `stow-source/` not `stow/`

The directory name is only a path we pass to `-d`. Naming it **`stow-source`** makes the command self-documenting:

```bash
stow -d stow-source -t "$HOME" -v shell guix-env quantum
```

There is no Stow multiverse rule that the folder must be called `stow`.

## Why `.zshrc.d` instead of owning all of `.zshrc`

### Short answer

Your **live** `~/.zshrc` on this Ubuntu laptop is already a full interactive config (history, prompt, plugins, Vega, Bun, …). If the machine pack stowed a **complete** `.zshrc`, Stow would either:

1. **Refuse** (file exists and is not a Stow link), or  
2. **Replace** your carefully tuned file and break daily shell use.

So we stow **small composable snippets** and a thin **`~/.zshrc.local`** that the real `.zshrc` already sources:

```zsh
# already in your ~/.zshrc
[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
```

`.zshrc.local` then loads ordered files:

```text
~/.zshrc.d/10-guix.zsh
~/.zshrc.d/15-history.zsh      # HISTSIZE/SAVEHIST >= 1000 (fleet baseline)
~/.zshrc.d/20-uv-python.zsh
~/.zshrc.d/30-dotnet-quantum.zsh
~/.zshrc.d/40-oh-my-posh.zsh
~/.zshrc.d/50-power.zsh        # rebootf / powerofff (ignore inhibitors)
```

### Mental model (not a daemon)

Nothing here is a system **daemon**. At login/interactive shell start:

1. zsh reads `~/.zshrc` (one-time per shell).  
2. That script `source`s other files — plain shell, like `#include`.  
3. **systemd** (or later Guix **Shepherd**) starts *services* in the background; shell config is unrelated.

| Concept | What it is | Example |
|---------|------------|---------|
| Shell config | Text run when **you** open a terminal | `.zshrc`, `.zshrc.d/*` |
| Init / service manager | Process tree for **system** services | systemd on Ubuntu; Shepherd on Guix System |
| Stow | Symlink manager for **files** | `stow-source/shell` → `$HOME` |

### Why split files?

- **Portable pack** can grow without fighting Ubuntu’s default zshrc.  
- **Same pattern** as `/etc/profile.d/` on many distros: drop a file, get behavior.  
- **Ordering** via numeric prefixes (`10-`, `20-`) is predictable.

If you ever want a pure Guix/home-managed shell with **no** distro zshrc, a single full `.zshrc` in Stow becomes fine — that is a later stage choice.

## Packages in this pack

| Package | Maps into $HOME | Purpose |
|---------|-----------------|---------|
| `shell` | `.zshrc.d/*`, `.zshrc.local` | PATH, Guix, uv, quantum env |
| `guix-env` | `.config/guix/…` | channels / packaging |
| `quantum` | `.config/quantum/…` | framework env defaults |
| `nvim` | `.config/nvim/…` | LazyVim editor configuration |
| `jupyter` | `.jupyter/jupyter_notebook_config.py`, `.config/systemd/user/qimono-jupyter.service` | Guix Notebook on `127.0.0.1:5005` |

## Apply

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64
./scripts/stow-apply.sh
```

## Conflicts

If stow refuses because a real file exists:

1. Diff the existing file vs the package copy.  
2. Move the existing file aside (`mv file file.bak`).  
3. Restow.  
4. Merge unique settings into the stow-managed file.

Avoid `stow --adopt` unless you understand it moves live files into the repo.

## Unstow

```bash
stow -d stow-source -t "$HOME" -D shell guix-env quantum
```
