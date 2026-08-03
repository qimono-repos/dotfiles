# stow package: emacs

**Status:** skeleton (feedback F10).

## Intent

Shared Emacs config (evil, etc.) usable across Ubuntu laptops, VPS, Guix System, later macOS/Windows where possible.

## Existing sources in this monorepo

| Path | Notes |
|------|-------|
| `dotfiles/gnu-guix/config/emacs/init.el` | Guix-oriented init |
| `dotfiles/ubuntu/.config/emacs/init.el` | Ubuntu archive path |

## Next steps

1. Choose a **single** canonical `init.el` (+ `early-init.el` if needed).  
2. Place files under `stow-source/emacs/.config/emacs/`.  
3. Add package to `scripts/stow-apply.sh` `PACKAGES=(… emacs)`.  
4. Guix already lists `emacs` in `guix/manifests/base.scm`.

Do not stow until the canonical tree is chosen (avoid clobbering a live `~/.config/emacs`).
