# QA — fleet bootstrap, macOS (Homebrew)

Scope: `curl -fsSL https://qimono.online/install | sh | bash fleet/brew.sh` path.
Human + AI checklists.

## Pre-flight (fresh Mac)

- [ ] macOS 12+ (Sonoma/Ventura recommended)
- [ ] User is an Administrator (Homebrew requires `sudo` for install)
- [ ] Xcode Command Line Tools: `xcode-select -p` (one human dialog)

## macOS run

- [ ] Entrypoint downloads fleet kit to `~/.qimono/fleet`
- [ ] `brew.sh` ensures Xcode CLT (`xcode-select -p` resolves)
- [ ] Homebrew installed (Apple Silicon `/opt/homebrew`, Intel `/usr/local`)
- [ ] `eval "$(brew shellenv)"` on PATH in current run
- [ ] `brew bundle --file=fleet/Brewfile` completes
- [ ] Git, zsh, bun, uv, ripgrep, tmux, fzf, jq, nvim, opencode installed
- [ ] Dotfiles cloned to `~/source/repos/qimono-repos/dotfiles`

## Post-run verify (AI can run automatically)

- [ ] `command -v brew git zsh bun uv opencode`
- [ ] `brew --version` and `opencode --version`
- [ ] `brew bundle check --file=fleet/Brewfile` exits 0 (all satisfied)
- [ ] Repo cloned over HTTPS

## Known traps

- **Xcode CLT dialog blocks headless/CI** — `xcode-select --install` opens a
  GUI prompt; `brew.sh` waits for `xcode-select -p` to succeed.
- **Homebrew prefix differs by arch** — script checks `/opt/homebrew` then
  `/usr/local` explicitly.
- **`brew bundle` needs the `homebrew/bundle` tap** — included in Brewfile;
  `brew tap` auto-adds it.
