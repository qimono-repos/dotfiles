# ubuntu-mini-pc

Machine pack for **`qi-mini-pc-ubu-rr`** — the AMD desktop mini-PC in the
Qimono / Ying-Yang fleet. This is a **quantum workstation** pack.

Yoga (`ubuntu-len-yog-AMD64`) and HP (`ubuntu-hp-pro`) are **references**.
This tree is not a copy of either.

| Field | Value |
|-------|-------|
| Host | `qi-mini-pc-ubu-rr` |
| Hardware | AMD Ryzen 7 7730U + Radeon Vega 8, ~14.5 GiB RAM |
| OS | Ubuntu 26.04 LTS (Resolute) |
| Role | Qiskit / QML daily box |
| Sibling refs | `ubuntu-len-yog-AMD64` (fullest pack), `ubuntu-hp-pro` (Jupyter 5005) |

## Expected vs Actual

Run the live probe any time:

```bash
./scripts/status.sh
```

Day-1 target (what “green” means):

| Check | Expected |
|-------|----------|
| Guix user profile | `python`, `uv`, `jupyter`, `emacs`, `stow`, `gcc-toolchain`, `zlib`, `openssl`, `pkg-config`, `glibc-locales` |
| Developer `python3` | `~/.guix-profile/bin/python3` (Guix 3.11). Apt `/usr/bin/python3` stays for Ubuntu shebangs. |
| `uv` | Guix `uv` first on PATH |
| Jupyter UI | Guix `jupyter` on **127.0.0.1:5005** |
| Config | `~/.jupyter/jupyter_notebook_config.py` (stow) |
| Unit | `qimono-jupyter.service` enabled at user login |
| Auth | `~/.secrets/jupyter_auth.py` (hash only, not git) |
| Shared Qiskit | `~/source/repos/qimono-repos/quantum-workspace` using **Guix python** |

## Day-one ritual

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-mini-pc
chmod +x scripts/*.sh
./scripts/bootstrap.sh          # profile + stow + jupyter unit; STOPS before auth
./scripts/setup-jupyter-auth.sh # YOU: password once
./scripts/install-quantum-python.sh
./scripts/status.sh
```

Then open **http://127.0.0.1:5005**.

`guix package -m` **replaces** the user profile. The only safe manifest is
[`guix/manifests/profile-full.scm`](./guix/manifests/profile-full.scm).
If you `guix install` something extra, add it to that file before the next `-m`.

## Layout

```
ubuntu-mini-pc/
  README.md
  MACHINE.md
  docs/quantum.md
  docs/python-path.md
  docs/jupyter.md
  docs/flatpak-guix.md
  guix/manifests/profile-full.scm
  scripts/
  stow-source/shell/          # .zshrc.local + .zshrc.d (no full .zshrc)
  stow-source/jupyter/
  QA/
  tests/smoke-tests/
```

## What this pack will not do (day-1)

- Uninstall apt `python3`
- `uv python install 3.12` (second CPython)
- Stow a replacement `~/.zshrc` (Kepler / Vega live there)
- Guix browsers, Rust, Q#, PennyLane, snap removal
- Create `qu/qiskit/.venv` — that waits until this chart is green
