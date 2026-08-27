# QA — fleet bootstrap, Linux / Ubuntu (Guix-first)

Scope: `curl -fsSL https://qimono.online/install | sh` on a fresh Ubuntu box.
Human + AI checklists (`- [ ]` / `- [x]`).

## Pre-flight (fresh box)

- [ ] Machine has `curl` + `tar` (or the script's apt step installs them)
- [ ] User has `sudo` and can type a password
- [ ] DNS: `https://qimono.online/install` resolves (or use raw URL)

## Linux run

- [ ] Entrypoint downloads the fleet kit to `~/.qimono/fleet`
- [ ] `guix.sh` apt-installs `curl git zsh tar` (only missing ones)
- [ ] Repo cloned to `~/source/repos/qimono-repos/dotfiles` (HTTPS, no auth)
- [ ] Pack detected correctly (ARM64/AMD64/hp-pro/mini-pc/ubuntu)
- [ ] Guix binary installed (sudo): `guix --version` works
- [ ] Guix daemon running: `pgrep -x guix-daemon`
- [ ] Substitute keys authorized (finish-guix-binary.sh succeeded)
- [ ] Pack `bootstrap.sh` completed: stow applied, quantum/uv OK
- [ ] New shell: `zsh` prompt shows, `guix` on PATH

## Post-run verify (AI can run automatically)

- [ ] `command -v guix git zsh curl tar`
- [ ] `git -C ~/source/repos/qimono-repos/dotfiles rev-parse --is-inside-work-tree` == true
- [ ] `guix describe` returns (daemon answers)
- [ ] `ls ~/.zshrc.d/ | sort` matches expected snippet set

## Known traps

- **ARM64 Guix tarball lacks `/usr/local/bin/guix`** → `finish-guix-binary.sh`
  is mandatory (symlink + keys + systemd unit).
- **Guix needs userns (AppArmor)** → `install-host-sysctl.sh` sets
  `apparmor_restrict_unprivileged_userns=0`.
- **Guix tarball download on first run is large** and network-dependent; the
  script stages to `/tmp/opencode/`.
