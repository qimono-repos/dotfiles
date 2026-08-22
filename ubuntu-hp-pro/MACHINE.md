# MACHINE.md — HP ProBook 440 G9 (`ubuntu-hp-pro` pack)

Snapshot of the host this pack targets. Refresh after major hardware/OS changes.

**Captured:** 2026-08-22 on the ProBook during Yoga-parity porting session.

## Hardware

| Item | Detail |
|------|--------|
| Vendor / model | HP ProBook 440 14 inch G9 Notebook PC |
| Board | HP 8A9E |
| Chassis | laptop |
| Firmware | Insyde U85 Ver. 01.18.01 (2026-05-04) |
| CPU | 12th Gen Intel Core i7-1255U (Alder Lake, 10c/12t: 2P+8E) |
| Freq | 0.4–4.7 GHz |
| Virtualization | **VT-x** (Intel peer of AMD-V); `/dev/kvm` present (group `kvm`) |
| GPU | Intel Iris Xe Graphics (Alder Lake-UP3 GT2) via Mesa — **no discrete GPU, no CUDA/ROCm story needed** |
| RAM | **30 GiB** total + 24 GiB swap file (`/swap.img`, swappiness 60) — roomiest fleet node; can host `gemma4:12b` class models (see `../llm/docs/local-llm.md` sizing note) |
| Storage | WD Green SN350 1TB NVMe |
| Partitioning | dual-boot style: EFI 200M + Windows NTFS (~542G) + Ubuntu ext4 **388G** root |
| Root FS | `/dev/nvme0n1p5` ext4, ~268G free at snapshot |

## Software (host)

| Layer | Version / notes |
|-------|-----------------|
| OS | Ubuntu 26.04 LTS |
| Kernel | Linux 7.0.0-30-generic x86_64 |
| Shell | zsh; `.zshrc` sources `~/.zshrc.local` → `~/.zshrc.d/*.zsh` (stow-managed) |
| Desktop | GNOME |
| Guix | post-pull at `~/.config/guix/current/bin/guix` (gen 1, 2026-08-06), channels include **nonguix** |
| Profile manifest | `guix/profile-manifest.scm` — SINGLE SOURCE OF TRUTH incl. `vscodium-fixed` (license-phase workaround) |
| Host sysctl | `/etc/sysctl.d/99-guix-userns.conf` installed, live `apparmor_restrict_unprivileged_userns=0` ✓ (browsers reboot-safe) |
| Ollama | binary at `/usr/local/bin/ollama`; service installed but **inactive** — enable = user sudo step |
| .NET | not observed yet (`docs` say host Microsoft packages are session-2+) |
| User | `qi` (uid 1000), sudo group |

### Hostname caveat

This machine's static hostname is **`qimono-localhost`** — which every doc assigns to the
Yoga SSH server (`ubuntu-len-yog-AMD64`). Until renamed, `ssh qimono-localhost` from here
resolves to *itself* (see `README_SSH_CLIENT.md` checklist). Candidate rename for a sudo
session: `hostnamectl hostname hp-pro`.

## Fleet position

| Node | RAM | Role |
|------|-----|------|
| Yoga (`ubuntu-len-yog-AMD64`) | 6.5 GiB | reference pack, terminal copilot node |
| mini-pc (`ubuntu-mini-pc`) | 14.5 GiB | quantum workstation, heavy LLMs |
| **hp-pro (this)** | **30 GiB** | daily driver; roomiest x86_64 node |

## Refresh commands

```bash
hostnamectl
lscpu | head -30
free -h
df -h /
which guix && guix describe | head -5   # must be …/current/bin/guix + nonguix
guix package -I                          # should match guix/profile-manifest.scm
sysctl kernel.apparmor_restrict_unprivileged_userns   # 0
```
