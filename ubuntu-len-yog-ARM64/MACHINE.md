# MACHINE.md — Lenovo Yoga Slim 7 Snapdragon (`ubuntu-len-yog-ARM64`)

Snapshot of the host this pack targets. Refresh after major hardware/OS changes.

**Captured:** 2026-08-27 via `scripts/machine-discovery.sh` on `qi-yoga-ubu-rr-lts`.

> This is the **ARM64 sibling** of the AMD Yoga pack. No x86_64 blobs — every
> tool either ships for `aarch64-linux` (Guix/Nix) or is host apt.

## Hardware

| Item | Detail |
|------|--------|
| Vendor / model | Lenovo Yoga Slim 7 14Q8X9 (SKU 83ED) |
| Chassis | laptop |
| Firmware | NHCN62WW (2025-12-02) |
| CPU | Qualcomm **Snapdragon X Elite** (Oryon), 12 cores / 12 threads |
| ISA | aarch64 (ARMv8/ARMv9) — NO x86_64, NO AVX |
| Virtualization | **`/dev/kvm` ABSENT** on this silicon |
| RAM | **30 GiB** total + 8 GiB swap (roomy — good for sims) |
| Storage | NVMe `p5` ext4 **380 GiB** root, ~336 GiB free at snapshot |
| OS | Ubuntu **26.04.1 LTS** (`resolute`) |
| Kernel | `6.7.2.0-13-qcom-x1e` (aarch64) |

### Architecture implications

- Focuses on hosting snapshots of the Oryon CPU with **no x86_64-only blobs**.
- No KVM → Kubernetes/emulator VMs not available locally (matches the other
  Snapdragon notes); keep heavy isolation to **podman** (user-namespace based,
  does not need KVM).
- Guix substitutes for `aarch64-linux` are available (incl. bordeaux/ci);
  prefer `guix install` when a package exists, then host apt/snap.

## Guix-first policy (this pack)

Package manager ranking (shared across Qimono Linux laptops):

1. **guix** · 2. **apt** · 3. **snap** · 4. **podman** · 5. **nix**

## Sibling machines

| Host pack | Arch | Notes |
|-----------|------|-------|
| `ubuntu-len-yog-AMD64` | x86_64 | AMD Yoga 7 (Ryzen + Radeon), ~6.5 GiB RAM |
| `ubuntu-len-yog-ARM64` (this) | aarch64 | Snapdragon X Elite Yoga, 30 GiB RAM |
| `ubuntu-hp-pro` | x86_64 | Intel ProBook 440 G9, 30 GiB |
| `ubuntu-mini-pc` | x86_64 | Ryzen 7 7730U quantum workstation |

## Refresh commands

```bash
hostnamectl
lscpu | head -20
free -h
df -h /
guix --version | head -1
guix package -I
python3 --version
```
