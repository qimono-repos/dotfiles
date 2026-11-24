# MACHINE.md — vi-wendy (`fedora/vi-wendy` pack)

Snapshot of the host this pack targets. Refresh after major hardware/OS changes.

**Captured:** 2026-11-22 on `vi-wendy` with `scripts/machine-discovery.sh`.

## Hardware

| Item | Detail |
|------|--------|
| Vendor / model | EXO S.A. Smart E16Plus notebook |
| Chassis | laptop |
| CPU | Intel Atom x5-Z8350, 4 cores / 4 threads, 0.48–1.92 GHz |
| Architecture | x86_64 |
| Virtualization | VT-x; `/dev/kvm` present (capability only, not a performance promise) |
| GPU | Intel Atom x5-E8000/J3xxx/N3xxx integrated graphics |
| RAM | 3.7 GiB |
| Swap | 3.7 GiB zram |
| Storage | 29.1 GB eMMC, device name `HBG4a2` (confirmed by `fwupd`) |
| Partitions | EFI 600M vfat + `/boot` 1G ext4 + 27.5G btrfs with `/` and `/home` subvolumes |
| Free space at snapshot | ~9.4 GiB on the shared btrfs partition |
| Network | `wlan0` only, 2.4 GHz, DHCP; no wired NIC observed |
| Firmware | UEFI; Secure Boot disabled; platform in Setup Mode |
| Boot | Fedora via `\EFI\FEDORA\SHIMX64.EFI`; removable-device and network boot entries present |
| Power | 71% at 2026-11-22 20:16 (-03), 31.4/44.3 Wh, UPower reported ~4.5 h remaining; AC offline; discharge monitor active |

## Software (host)

| Layer | Version / notes |
|-------|-----------------|
| OS | Fedora Linux 35 Workstation — end-of-life and security-stale |
| Kernel | Linux 5.18.5-100.fc35.x86_64 (2022) |
| Desktop | GNOME |
| Package managers | `dnf`, `snap`, `podman`, `flatpak` present; no `guix`, `stow`, `uv`, `nix`, `docker`, `dotnet`, or `cargo` on PATH |
| GitHub CLI | `gh` 2.105.0 at `~/.local/bin/gh` (user-owned install) |
| Git identity | `Qimono <albert.tan.2.pi.0@gmail.com>` (global config) |
| Git remote | `git@github.com:qimono-repos/dotfiles.git` via SSH |
| SSH server | `sshd.service` inactive + disabled at snapshot |
| Firewall | active `FedoraWorkstation`; allows `ssh`, mDNS, DHCPv6, Samba client, and a broad `1025-65535/tcp,udp` port range |
| Remote access | TeamViewer package/service present at snapshot; removal is documented in [`TEAMVIEWER-REMOVAL.md`](./TEAMVIEWER-REMOVAL.md) |

## Role assessment

| Proposed role | Verdict | Reason |
|---------------|---------|--------|
| SSH server / server-manager host | **No** | No `sshd`, no wired network, EOL OS, DHCP-only Wi‑Fi, laptop power profile, broad firewall ports, and very little RAM headroom. |
| First 100% bare-metal Guix System | **Authorized but constrained** | User explicitly accepted destructive migration. 3.7 GiB RAM and ~9.4 GiB free are below a comfortable Guix/Nonguix build envelope; expect slow substitutes and consult `../../lobby-files/README.md:5-7` for resource/SIGSEGV concerns. |
| Portable Guix lobby client / diagnostic canary | **Yes** | x86_64 UEFI with removable boot support; use an external USB SSD for experiments. See `../../GUIX-OS-AS-LOBBY.md:3,9-11`. |
| Low-priority SSH client to manager hosts | **Yes** | SSH client and key auth work; GitHub SSH access is verified. |
| Heavy quantum/LLM/container host | **No** | Atom CPU, 3.7 GiB RAM, eMMC storage, and 2.4 GHz Wi‑Fi. |

## Promotion gates

Do not assign this host a server role until all are true:

- Supported OS with current security updates.
- Wired network or a reliable overlay network with documented recovery access.
- At least 8 GiB RAM and a real SSD with 64 GiB free.
- `sshd` intentionally enabled, key-only, with a tested non-root admin path.
- Firewall narrowed to required services; the `1025-65535` range reviewed or removed.
- TeamViewer absent and remote-control ownership documented.

## Fleet position

| Node | RAM | Role |
|------|-----|------|
| Yoga (`ubuntu-len-yog-AMD64`) | 6.5 GiB | reference pack, terminal copilot / documented SSH server |
| mini PC (`ubuntu-mini-pc`) | 14.5 GiB | quantum workstation; preferred bare-metal Guix candidate |
| HP ProBook (`ubuntu-hp-pro`) | 30 GiB | daily driver; roomiest x86_64 node |
| ARM Yoga (`ubuntu-len-yog-ARM64`) | 30 GiB | aarch64 Guix-first sibling |
| VPS (`vps-ubuntu`) | 3.8 GiB | server-native Guix-first pack |
| **vi-wendy (this)** | **3.7 GiB** | legacy Fedora lab host; authorized Guix first-citizen migration target |

## Refresh commands

```bash
./fedora/vi-wendy/scripts/machine-discovery.sh
git -C ~/source/repos/qimono-repos/dotfiles remote -v
ssh -o BatchMode=yes -T git@github.com
gh auth status
```

See [`GITHUB.md`](./GITHUB.md) for access details and [`QA/`](./QA/) for acceptance checks.
