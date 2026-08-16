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

## Pack policy

| Rank | Manager | Role |
|------|---------|------|
| 1 | GNU Guix | Developer python, uv, jupyter, stow, native libs |
| 2 | apt | Kernel, desktop, `#!/usr/bin/python3` for Ubuntu tools |
| 3 | snap | Existing desktop apps (do not touch on day-1) |
| 4 | podman | Escape hatch later |

See [docs/python-path.md](./docs/python-path.md) and [docs/quantum.md](./docs/quantum.md).
