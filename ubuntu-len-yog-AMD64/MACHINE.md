# MACHINE.md — Lenovo Yoga AMD64 (`ubuntu-len-yog-AMD64`)

Snapshot of the host this pack targets. Refresh after major hardware/OS changes.

**Captured:** 2026-08-02 on `qimono-localhost`.  
**Host sysctl note:** 2026-08-03 — Guix Epiphany needs `/etc/sysctl.d/99-guix-userns.conf` (see below).

## Hardware

| Item | Detail |
|------|--------|
| Vendor / model | Lenovo Yoga 7 2-in-1 14AHP9 |
| SKU / MT | 83DK · `LENOVO_MT_83DK_BU_idea_FM_Yoga 7 2-in-1 14AHP9` |
| Chassis | convertible (2-in-1) |
| Firmware | P9CN33WW (2026-03-27) |
| CPU | AMD Ryzen 5 8640HS w/ Radeon 760M Graphics |
| Cores / threads | 6 cores / 12 threads (Zen 4 / Phoenix) |
| Freq | ~0.4–3.5 GHz (boost) |
| ISA extras | AVX2, AVX-512 family flags present on this silicon |
| Virtualization | **AMD-V** (CPU feature; see teach-in below) |
| GPU | AMD/ATI HawkPoint1 (Radeon 760M iGPU) via Mesa |
| DRM | `/dev/dri/card1`, `renderD128` |
| RAM | **~6.5 GiB** total (+ 4 GiB swap) — **tight for big sims** |
| Storage | Micron NVMe 512 GB (`MTFDKCD512TGE…`) |
| Partitioning | dual-boot style: EFI + Windows NTFS (~320G) + Ubuntu ext4 **~156G** root |
| Root FS | `/dev/nvme0n1p5` ext4 ~153G usable; ~75G free at snapshot |

### AMD-V (not Hyper-V)

**AMD-V** is the AMD CPU virtualization extension (peer of Intel **VT-x**).  
**Hyper-V** is a Microsoft *hypervisor product* that *uses* such extensions on Windows.

On this Ubuntu host, the useful stack for Android / non-conventional-screen emulators (Ying-Yang frontend) is **AMD-V → KVM → QEMU/Android Emulator**, not Hyper-V.

Full teach-in: [docs/teach-amd-v.md](./docs/teach-amd-v.md)

```bash
lscpu | grep -i virtualization   # expect AMD-V
ls -l /dev/kvm 2>/dev/null || echo "install qemu-kvm; add user to kvm"
```

### Implications for quantum work

- Prefer **small circuits**, sparse sims, and **remote backends** (IBM Quantum, Azure Quantum, Amazon Braket) over large local state-vector runs.
- Keep simulators process-limited; close browsers/IDE when running heavy jobs.
- Use `podman` for disposable heavy environments so the host RAM stays predictable.
- Guix store lives on root (`/gnu/store` ~3.5G at snapshot) — pull carefully; `guix gc` when disk pressure rises.

## Software (host)

| Layer | Version / notes |
|-------|-----------------|
| OS | Ubuntu 26.04 LTS (`resolute`) |
| Kernel | Linux 7.0.0-28-generic x86_64 |
| Shell | zsh (`/usr/bin/zsh`) — interactive config in `~/.zshrc` |
| Desktop | GNOME (Ubuntu desktop path; snaps for several apps) |
| Guix | **1.5.0** at `/usr/local/bin/guix` |
| Guix profile | `~/.guix-profile` → `/var/guix/profiles/per-user/qi/guix-profile` |
| Python (apt/host) | **3.14.4** at `/usr/bin/python3` |
| Python (Guix) | **3.11.x** available (`guix install python`) — preferred for scientific stacks |
| uv | **not installed** at snapshot; available as Guix package `uv@0.6.x` |
| stow | **not installed** at snapshot; available as Guix package `stow@2.4.x` |
| .NET | **SDK 10.0.110** at `/usr/lib/dotnet` |
| Podman | **5.7.0** |
| Snap | present (firefox, discord, pycharm, obsidian, vlc, …) |
| Editors | VS Code (`code`), Guix emacs 30.2, Guix neovim 0.11.5, PyCharm snap |
| JS | Bun 1.3.x in `~/.bun`; system `node`/`npm` not on PATH |
| Extra SDKs | Amazon Vega / Kepler under `~/vega` |
| Local LLM | **Ollama 0.32.15** (`/usr/local/bin/ollama`), service enabled+boot; model **`gemma4:e2b`** pulled 2026-08-21 — fleet standard, see `../llm/docs/local-llm.md` |
| User | `qi` (uid 1000), sudo group |

### Required host sysctl (Guix sandboxes)

Ubuntu defaults `kernel.apparmor_restrict_unprivileged_userns=1`. That breaks Guix store  
`bwrap` (Epiphany/WebKit): `setting up uid map: Permission denied`.

| Item | Path / value |
|------|----------------|
| Pack drop-in | `host-sysctl/99-guix-userns.conf` |
| Installed | `/etc/sysctl.d/99-guix-userns.conf` |
| Live value | must be **`0`** |
| Install script | `./scripts/install-host-sysctl.sh` |

```bash
./scripts/install-host-sysctl.sh
sysctl kernel.apparmor_restrict_unprivileged_userns   # 0
# after reboot, same check — if 1, drop-in missing
```

Sibling pack (same drop-in): `dotfiles/ubuntu-hp-pro/`.

### Guix packages already installed (user profile)

- `neovim` 0.11.5  
- `emacs` 30.2  
- `openjdk` 25 (jdk)  
- `git` 2.52.0  
- `ripgrep` 15.1.0  
- `fd` 10.2.0  
- `fzf` 0.67.0  

**Also installed later:** `stow`, `python` 3.11, `uv` (Guix).  

**Gap (historical):** Guix profile was **not** sourced in live zsh `PATH` at first snapshot. Fixed via `stow-source/shell` + `guix-env`.

### Channels

Repo reference: `dotfiles/gnu-guix/config/guix/channels.scm` includes **nonguix**. Live `~/.config/guix/channels.scm` may differ — keep them aligned intentionally.

## Disk map (high level)

```
nvme0n1 476.9G
├─ p1  200M  vfat   /boot/efi
├─ p2   16M
├─ p3  ~320G ntfs   (Windows)
├─ p4  ~802M ntfs
└─ p5  ~156G ext4   /   ← Ubuntu + /gnu/store + $HOME
```

## Sibling machines

| Host pack | Arch | Notes |
|-----------|------|-------|
| `ubuntu-len-yog-AMD64` (this) | x86_64 | Ryzen + Radeon iGPU |
| Snapdragon Yoga (planned) | aarch64 | separate stow pack; no x86_64 blobs |

Do not assume AMD GPU drivers or x86_64-only Guix substitutes on the Snapdragon machine.

## Refresh commands

```bash
hostnamectl
lscpu | head -30
free -h
df -h /
guix --version | head -1
guix package -I
python3 --version
dotnet --list-sdks
podman --version
```
