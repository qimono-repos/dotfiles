# Checklist — Agent (`ubuntu-mini-pc`)

Read `README.md` + this file before mutating the host.

## Must

- [x] Probe first (`./scripts/status.sh`, `guix package -I`)
- [x] Only `-m` file is `guix/manifests/profile-full.scm` (must list emacs+stow+python+uv+jupyter+native)
- [x] Do not `uv python install`
- [x] Do not `apt remove python3`
- [x] Do not stow a full `.zshrc`
- [x] Do not commit `~/.secrets/`
- [x] `setup-jupyter-auth.sh` is **human** (getpass) — do not fake a hash
- [x] After host changes: update `$HOME/LOCAL_MACHINE.md` Expected vs Actual
- [x] Commit on `dotfiles` `main`; do not push unless asked

## Must not (day-1)

- [x] Guix browsers / snap remove / rust / Q# / PennyLane
- [x] Create `qu/qiskit/.venv` (later session)
- [x] `sudo` / `/etc` sysctl (not needed until Guix WebKit apps)
