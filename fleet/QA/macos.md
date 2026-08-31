# QA — fleet bootstrap, macOS (Homebrew → darwin pack)

Scope: `curl -fsSL https://qimono.online/install | sh | bash fleet/brew.sh` path.
Human + AI checklists. The darwin pack (stow, Apple Container, Podman, dev
machine, Guix-in-container) owns the deeper checks in `darwin/QA/`; this file
covers the fleet-level macOS run.

## Pre-flight (fresh Mac)

- [ ] **macOS 26 "Tahoe" minimum** (Apple Container hard requirement)
- [ ] Apple Silicon (`uname -m` == `arm64`)
- [ ] User is an Administrator (Homebrew + `sudo bash ...guix-system-install`)
- [ ] Xcode Command Line Tools: `xcode-select -p` (one human dialog)

## macOS run

- [ ] Entrypoint downloads fleet kit to `~/.qimono/fleet`
- [ ] `brew.sh` ensures Xcode CLT (`xcode-select -p` resolves)
- [ ] Homebrew installed at `/opt/homebrew` (Apple Silicon)
- [ ] `eval "$(brew shellenv)"` on PATH in current run
- [ ] `brew bundle --file=fleet/Brewfile` completes (incl. `podman`, `stow`)
- [ ] Dotfiles cloned to `~/source/repos/qimono-repos/dotfiles`
- [ ] darwin pack `bootstrap.sh` dispatched:
      stow shell · container CLI+Podman · `container system start` ·
      machine `qi-dev` created · Guix-in-container scripts written to `$HOME`

## Post-run verify (AI can run automatically)

- [ ] `command -v brew git zsh bun uv opencode podman stow container`
- [ ] `brew --version`, `opencode --version`, `container --version`
- [ ] `brew bundle check --file=fleet/Brewfile` exits 0
- [ ] Repo cloned over HTTPS
- [ ] `container system status` running; `container machine list` shows `qi-dev`

## In-machine handoff (Guix layer, see `darwin/QA/`)

- [ ] `container machine run qi-dev` → `sudo bash ~/.qimono/guix-system-install.sh`
- [ ] → `bash ~/.qimono/guix-user-bootstrap.sh`
- [ ] `guix shell hello -- hello` inside the machine

## Known traps

- **macOS < 26 breaks Apple Container silently** — networking/VM failures; the
  gate in `brew.sh`/`bootstrap.sh` refuses early. Update macOS first.
- **Upstream Ubuntu/Debian images can't be machine bases** — no init at
  `/sbin/init`; use `darwin/scripts/container-machine-create.sh` (systemd image).
- **Rosetta 2 required only to BUILD images** (execution is native).
- **First `container system start` downloads a Linux kernel** (one-time prompt).
- **Don't migrate machine state** — recreate `qi-dev` if `$HOME` mirroring is
  flaky (v1.0 username-mirror race).
- **`container` brew formula may lag** a release — `install-container.sh`
  falls back to Apple's signed `.pkg` from `github.com/apple/container`.
- **Xcode CLT dialog blocks headless/CI** — `brew.sh` polls `xcode-select -p`.