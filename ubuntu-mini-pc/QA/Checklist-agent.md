# Checklist — Agent (`ubuntu-mini-pc`)

Read `README.md` + this file before mutating the host.

## Must

- [ ] Probe first (`./scripts/status.sh`, `guix package -I`)
- [ ] Only `-m` file is `guix/manifests/profile-full.scm` (must list emacs+stow+python+uv+jupyter+native)
- [ ] Do not `uv python install`
- [ ] Do not `apt remove python3`
- [ ] Do not stow a full `.zshrc`
- [ ] Do not commit `~/.secrets/`
- [ ] `setup-jupyter-auth.sh` is **human** (getpass) — do not fake a hash
- [ ] After host changes: update `$HOME/LOCAL_MACHINE.md` Expected vs Actual
- [ ] Commit on `dotfiles` `main`; do not push unless asked

## Must not (day-1)

- [ ] Guix browsers / snap remove / rust / Q# / PennyLane
- [ ] Create `qu/qiskit/.venv` (later session)
- [ ] `sudo` / `/etc` sysctl (not needed until Guix WebKit apps)
