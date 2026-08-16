# MACHINE.md — ubuntu-mini-pc (`qi-mini-pc-ubu-rr`)

Pack-scoped inventory. Refresh after hardware/OS/profile changes.
Canonical home inventory remains `$HOME/LOCAL_MACHINE.md`.

**Captured:** 2026-08-16 on `qi-mini-pc-ubu-rr`.

## Hardware

| Item | Detail |
|------|--------|
| Chassis | Desktop mini-PC |
| CPU | AMD Ryzen 7 7730U (Zen 3 / Cezanne) — 8 cores / 16 threads |
| GPU | AMD Radeon Vega 8 (Barcelo / Renoir iGPU), Mesa |
| RAM | ~14.5 GiB usable + 4 GiB swap (`/swap.img`) |
| Storage | WD BLACK SN7100 500 GB NVMe — root ext4 ~457 GiB |
| Virt | AMD-V present |
| Arch | `x86_64` / `amd64` |

Implications for quantum: pedagogical circuits in `qu/` (Shor-15, Grover N=8,
TSP-4) fit locally. This is **not** the 6.5 GiB Yoga — dense sims still have
a ceiling, but day-1 work does not need cloud QPUs.

## Software (host, before this pack)

| Layer | Notes |
|-------|-------|
| OS | Ubuntu 26.04 LTS (`resolute`), kernel 7.0.x, GNOME + Wayland |
| Shell | `/usr/bin/zsh` — live `~/.zshrc` → `dotfiles/ubuntu/.zshrc` |
| Guix | 1.5.0 at `/usr/local/bin/guix`; user profile was **emacs + stow only** |
| Python (apt) | 3.14.4 at `/usr/bin/python3` — OS only |
| uv (host) | 0.12.0 at `~/.local/bin/uv` — shadowed once Guix uv is on PATH |
| Extra SDKs | Kepler / Vega under `~/kepler` and `~/vega` (leave them) |
| Browser | Google Chrome via APT; several browser snaps |

## Software (after day-1, 2026-08-16)

| Layer | Actual |
|-------|--------|
| Kernel | `7.0.0-29-generic` |
| Guix user profile | generation 3: emacs, stow, python 3.11.14, uv 0.6.12, jupyter 1.0.0, gcc-toolchain, zlib, openssl, pkg-config, glibc-locales |
| Developer `python3` | `~/.guix-profile/bin/python3` (3.11.14) |
| Apt `python3` | `/usr/bin/python3` (3.14.4) still present |
| Jupyter | `qimono-jupyter.service` enabled+active, http://127.0.0.1:5005 |
| Auth | `~/.secrets/jupyter_auth.py` mode 600 (hash only) |
| Shared Qiskit | `~/source/repos/qimono-repos/quantum-workspace` — qiskit 2.5.2 + aer 0.17.2 on Guix CPython |
| Kernel spec | `Python (quantum)` → workspace `.venv` |

## Pack policy

| Rank | Manager | Role |
|------|---------|------|
| 1 | GNU Guix | Developer python, uv, jupyter, stow, native libs |
| 2 | apt | Kernel, desktop, `#!/usr/bin/python3` for Ubuntu tools |
| 3 | snap | Existing desktop apps (do not touch on day-1) |
| 4 | podman | Escape hatch later |

See [docs/python-path.md](./docs/python-path.md) and [docs/quantum.md](./docs/quantum.md).
