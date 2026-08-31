# QA — Agent checklist (darwin pack)

Anti false-victory: the agent records **evidence** (real command output), not
intent. Run in order; tick only what actually passes. Applies to BOTH Macs
(MacBook Air + Mac mini).

## Host gate

- [ ] macOS ≥ 26: `sw_vers -productVersion` → e.g. `26.x`
- [ ] Apple Silicon: `uname -m` → `arm64`
- [ ] Xcode CLT: `xcode-select -p` resolves

## Homebrew

- [ ] `brew --version` ok; prefix `/opt/homebrew`
- [ ] `brew bundle check --file=fleet/Brewfile` exits 0
- [ ] `command -v git zsh ripgrep fzf tmux jq tree bun uv nvim opencode podman stow`
- [ ] Dotfiles cloned to `~/source/repos/qimono-repos/dotfiles`

## Apple Container

- [ ] `container --version` → v1.x
- [ ] `container system status` reports running/ready
- [ ] `podman --version` ok

## Dev machine

- [ ] `container machine list` shows `qi-dev` (marked default)
- [ ] `container machine run qi-dev` drops into a systemd Linux shell
- [ ] inside machine: `ps -p 1 -o comm=` → `systemd`
- [ ] inside machine: `ls -ld "$HOME"` exists; repo path visible (mirrored $HOME)

## Guix inside the machine

- [ ] `guix --version` along the lines of `guix (GNU Guix) 1.5.0`
- [ ] `guix package -I` lists darwin-base manifest packages (stow, git, tmux…)
- [ ] `guix shell hello -- hello` → `Hello, world!` (sandbox works)
- [ ] new shell: `which guix` resolves via `~/.guix-profile` (via 05-guix.zsh)

## Stow / shell

- [ ] `~/.zshrc` is a symlink into `darwin/stow-source/shell`
- [ ] new shell: oh-my-posh (catppuccin) renders; `alias dev` exists on macOS
- [ ] fresh shell: `/opt/homebrew/bin` first in `$PATH`

## Reboot-persistence

- [ ] After R1 (fresh macOS login): brew + container on PATH, machine `qi-dev` starts
- [ ] After R1: `container machine run qi-dev` → guix still on PATH (profile persists)