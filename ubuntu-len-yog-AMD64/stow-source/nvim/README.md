# stow package: nvim (LazyVim-oriented)

**Status:** skeleton (feedback F10).

## Intent

`~/.config/nvim` for LazyVim (or a thin native config) shared across machines.

## Next steps

1. Bootstrap LazyVim once on this host (or copy a known-good tree).  
2. Commit only **user** config (not all of `lazy-lock` noise if undesired).  
3. Tree layout:

```text
stow-source/nvim/.config/nvim/
  init.lua
  lua/…
```

4. Add `nvim` to `stow-apply.sh` when ready.

Guix package: `neovim` in `base.scm`.
