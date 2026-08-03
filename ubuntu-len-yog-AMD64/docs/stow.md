# Stow usage (this pack)

[GNU Stow](https://www.gnu.org/software/stow/) manages symlinks from package trees into `$HOME`.

## Install stow

Prefer Guix (rank 1):

```bash
guix install stow
# ensure profile is on PATH (see stow/shell package)
```

Fallback apt only if Guix is unavailable:

```bash
sudo apt install stow
```

## Packages in this pack

| Package | Maps into $HOME | Purpose |
|---------|-----------------|---------|
| `shell` | `.zshrc.d/*`, `.zshrc.local` fragment guidance | PATH, Guix, uv, quantum helpers |
| `guix-env` | `.config/guix/…` | channels / packaging hints |
| `quantum` | `.config/quantum/…` | env defaults for frameworks |

## Apply

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64
./scripts/stow-apply.sh
# equivalent:
# stow -d stow -t "$HOME" -v --restow shell guix-env quantum
```

## Conflicts

If stow refuses because a real file exists:

1. Diff the existing file vs the package copy.  
2. Move the existing file aside (`mv file file.bak`).  
3. Restow.  
4. Merge any unique settings into the stow-managed file.

Never force-overwrite with `stow --adopt` unless you understand it will move the live file into the repo.

## Unstow

```bash
stow -d stow -t "$HOME" -D shell guix-env quantum
```

## Integration with live `~/.zshrc`

This machine’s `~/.zshrc` already sources:

```zsh
[[ -r "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"
```

and we also drop snippets under `~/.zshrc.d/` loaded from `.zshrc.local`. That keeps the big Ubuntu zshrc untouched while this pack remains portable.
