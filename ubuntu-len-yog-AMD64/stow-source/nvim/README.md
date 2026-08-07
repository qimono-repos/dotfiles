# stow package: nvim (LazyVim-oriented)

**Status:** Active & Configured (stow linked).

## Intent

`~/.config/nvim` configured for LazyVim, shared across machines via GNU Stow.

## Structure

```text
stow-source/nvim/.config/nvim/
├── init.lua                  # Entrypoint loading config.lazy
└── lua/
    ├── config/
    │   ├── lazy.lua          # LazyVim bootstrap & spec loader
    │   ├── options.lua       # Custom options (scrolloff, relative numbers, etc.)
    │   ├── keymaps.lua       # Custom keybindings (e.g. jf/fj escape)
    │   └── autocmds.lua      # User autocmds
    └── plugins/
        └── example.lua       # Custom plugin overrides (e.g. Tokyonight theme)
```

## Management

- Package manager: Installed via Guix (`guix install neovim stow git ripgrep fd`)
- Apply symlinks: `./scripts/stow-apply.sh` (or `./scripts/install-neovim-lazyvim.sh`)
- Target: `$HOME/.config/nvim`
