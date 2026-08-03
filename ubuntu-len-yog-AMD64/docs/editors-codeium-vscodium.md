# Editors: Codeium, VSCodium, VS Code (stage 1)

**Chunk:** P3.3 · Feedback F6

## Landscape on this machine

| Editor | How it is present | Guix? |
|--------|-------------------|-------|
| **Emacs** | Guix profile 30.2 | Yes — keep via `base.scm` |
| **Neovim** | Guix profile 0.11 | Yes — LazyVim stow later |
| **VS Code** | Microsoft `code` (apt) | Proprietary; host OK |
| **PyCharm** | snap | Migrate later if desired |
| **VSCodium** | Not installed | Not in default Guix search |
| **Codeium** | Extension / language server | Not a Guix “IDE package” |

## Recommended Qimono policy

1. **Emacs + Neovim** = Guix-first, stow configs (`stow-source/emacs`, `stow-source/nvim`).  
2. **VS Code** = acceptable host proprietary tool (like Microsoft .NET).  
3. **Codeium** = install as **VS Code / Neovim / JetBrains extension**, not via apt.  
4. **VSCodium** = optional FOSS build of VS Code; install via upstream `.deb` or flatpak if Guix lacks it — do not force a broken Guix package.

## Codeium setup (no Guix required)

### VS Code

1. Open Extensions → search **Codeium**.  
2. Sign in / API key per vendor docs.  
3. Disable if RAM pressure (6.5 GiB) — AI extensions are heavy.

### Neovim

Prefer LazyVim / mason-managed LSP after `stow-source/nvim` is real:

- Codeium.nvim or Windsurf/Codeium official nvim plugin (names change — check current repo).  
- Keep API keys out of git (`~/.secrets`).

### Emacs

- `emacs-codeium` style packages exist in the wild; prefer MELPA/Guix emacs-xyz when available.  
- David Wilson / System Crafters style: declarative emacs packages via Guix home later.

## VSCodium options (when you want no Microsoft branding)

| Method | Rank | Notes |
|--------|------|-------|
| Upstream `.deb` | apt-ish | Simple on Ubuntu stage 1 |
| Flatpak | peer of snap | Sandboxed |
| Guix | 1 | Only if package appears after `guix pull` |

```bash
# discovery after pull
guix search codium
guix search vscodium
```

## What we will not do this chunk

- Replace working `code` with a half-broken Guix build.  
- Commit Codeium API tokens.  
- Install every AI extension by default (RAM).
