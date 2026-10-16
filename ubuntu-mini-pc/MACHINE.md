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
| Guix user profile | generation 7 (2026-10-16): emacs, stow, blender, bat, python 3.12.12, uv 0.10.12, jupyter 1.0.0, gcc-toolchain 16.2.0, zlib, openssl 3.5.7, pkg-config, glibc-locales, flatpak 1.16.6 |
| Developer `python3` | `~/.guix-profile/bin/python3` (3.12.12) |
| Apt `python3` | `/usr/bin/python3` (3.14.8) still present |
| Jupyter | `qimono-jupyter.service` enabled; **inactive** — `quantum-workspace` dir missing → CHDIR fails (needs recreate, see below) |
| Auth | `~/.secrets/jupyter_auth.py` mode 600 (hash only) |
| Shared Qiskit | `~/source/repos/qimono-repos/quantum-workspace` — qiskit 2.5.2 + aer 0.17.2 on Guix CPython |
| Kernel spec | `Python (quantum)` → workspace `.venv` |
| Flatpak | Guix 1.16.6 client; Flathub user remote; Alpaca 9.2.5. Run via `FLATPAK_BWRAP=/usr/bin/bwrap` (Ubuntu AppArmor) |

## Python profile target (applied 2026-10-16)

`guix/manifests/profile-full.scm` requests `python@3.12` so PROXORA's
`requires-python = ">=3.12"` is satisfied by the Guix interpreter — no non-Guix
Python is installed. Generation 7 now provides **python 3.12.12**; re-verify
with `./scripts/status.sh`.

Two traps fixed while applying it:

1. **`GUIX_PROFILE` clobber** — `~/.zshrc`'s installer block exports
   `GUIX_PROFILE=$HOME/.config/guix/current` before `~/.guix-profile/etc/profile`
   is sourced. That snippet prepends `${GUIX_PROFILE}/bin`, so the *pull*
   profile's bin was prepended and `~/.guix-profile/bin` (python3, uv, stow)
   never reached PATH. `stow-source/shell/.zshrc.d/10-guix.zsh` now pins
   `GUIX_PROFILE=$HOME/.guix-profile` for the user-profile source.
2. **Manifest completeness** — `blender` and `bat` were installed but not
   listed, so a bare `-m` would have deleted them. Both are now in
   `profile-full.scm` (which must stay complete).

## Pack policy

| Rank | Manager | Role |
|------|---------|------|
| 1 | GNU Guix | Developer python, uv, jupyter, stow, native libs, **flatpak client** |
| 2 | apt | Kernel, desktop, `#!/usr/bin/python3` for Ubuntu tools |
| 3 | snap | Existing desktop apps (do not touch on day-1) |
| 3.5 | Flathub | Vendor GUI gaps via Guix `flatpak --user` — see [docs/flatpak-guix.md](./docs/flatpak-guix.md) |
| 4 | podman | Escape hatch later |

See [docs/python-path.md](./docs/python-path.md) and [docs/quantum.md](./docs/quantum.md).
