# Guix as a "Fleet Lobby" (Portable Boot Environment)

**Status:** design notes / learning (not a fleet protocol yet).  
**Date:** 2026-11-10  
**Context:** `qi-mini-pc-ubu-rr` fleet, NVMe transplant workflow, removable-media boot.

## Core idea

Use a **minimal Guix System** on a removable drive as a universal **lobby after GRUB/UEFI boot menu**: boot the lobby on (almost) any machine, **mount the transplanted Ubuntu NVMe by stable identity** (`by-id` / serial / WWN/EUI / UUID), `chroot` into Ubuntu, repair for that hardware (initramfs, microcode, bootloader/ESP), then reboot into the "big Ubuntu host" when appropriate.

Guix is the **segway**, not necessarily the full daily developer machine. The developer environment remains Guix-first inside Ubuntu (dotfiles + `~/.guix-profile`), while the lobby provides a reproducible, declarative rescue/bring-up environment.

## UEFI/GRUB reality (why removable-first)

- **GRUB is not "in the UEFI chip".** UEFI firmware stores NVRAM boot entries (pointers). The actual bootloader binaries (`grubx64.efi`, `BOOTX64.EFI`, etc.) and `grub.cfg` live on an **EFI System Partition (ESP)** on disk.
- Adding a lobby entry to *this* machine's NVRAM is convenient but **not portable** when the NVMe moves to another chassis.
- **Portable approach:** put the lobby on a removable drive with its own ESP and the UEFI fallback path `EFI/BOOT/BOOTX64.EFI`. Boot via the machine's boot menu (`Esc`/`F12`/etc.) and select the removable device. No dependency on foreign NVRAM entries.

## Two-drive flow (this iteration)

| Drive | Role | This iteration (observed) | Notes |
|---|---|---|---|
| **Drive 1** | Guix **installer** media | `/dev/sdb` micro SD, model `STORAGE DEVICE`, currently `GUIX_X86_64-LINUX_1.5.0` ISO | Used only to install the lobby. **Counterfeit capacity:** `f3probe` reported announced 58.59 GB but real usable ~3.96 GB (limbo). The Guix 1.5.0 installer ISO fits; treat as **installer-only / sealed** after validation. |
| **Drive 2** | Guix **lobby** target (persistent) | `/dev/sda` thumbdrive `USB DISK 2.0`, **14.5 GB**, reformatted as `ext4` label `qi-thumb` (UUID `c5d9df16-bfe6-4a20-9165-789c7896ddf5`) | **This iteration:** install the first lobby here, then **use this lobby elsewhere** (boot from USB on other machines). 14 GB is small for 2026 but enough to prototype the procedure; easy to identify by label/capacity. Prefer a faster USB SSD for a long-term lobby later. |

**Never target:** `/dev/nvme0n1` (WD_BLACK SN7100 500GB, Ubuntu host). Always confirm with `lsblk -o NAME,MODEL,SIZE,TRAN,LABEL,FSTYPE,UUID` inside the installer.

### Steps
1. **Networking (do this first / be prepared):** the Guix install usually needs network to download substitutes. **Easiest/fastest: plug in a LAN cable** before or during the installer (sometimes inconvenient in 2026, but worth it). Wi‑Fi can work but may need extra steps in the live environment.
2. Boot the machine from **Drive 1** (UEFI boot menu → removable/SD). The Guix image is a hybrid ISO; pick the **UEFI** entry for the removable device when shown.
3. **Boot keys (this mini-pc, AMI BIOS 5.19 2023-09-11, generic DMI):** one-time boot menu observed/attempted via **`Esc`** (confirm exact behavior on your unit); if the fast boot menu isn’t available, **change boot priority in UEFI setup** (`Del`/`F2` common on AMI) to boot the SD/USB (UEFI) first, then revert later if desired. From Ubuntu: `systemctl reboot --firmware-setup`.
4. Expect the **Guided Graphical Installation** to be a **text-based ncurses/TUI** (dialog boxes) — *not* a Calamares/Qt GUI. TTY1 is the installer; root shells on **TTY3–TTY6** (`Ctrl+Alt+F3`…`F6`), docs on **TTY2** (`Ctrl+Alt+F2`).
5. **Disk selection gotcha (observed 2026-11-10):** the guided installer may show *“The installation device as well as the small devices are filtered”* and list only the NVMe. Typical causes: the **boot/source device** is filtered (SD card running the ISO) and the target may be filtered as **small** (e.g. 14.5 GB `qi-thumb`). **Workaround:** switch to another TTY and use **manual install** (`lsblk` → partition/mkfs → `herd start cow-store /mnt` if present → `guix system init`) targeting **Drive 2 only**. Re-verify identity every time:
   ```sh
   lsblk -o NAME,MODEL,SIZE,TRAN,LABEL,FSTYPE,UUID
   ```
   Target only `qi-thumb` / `USB DISK 2.0` 14.5G — **never** `nvme0n1` / `WD_BLACK`.
6. If using the guided path (when the disk is visible), install to **Drive 2 only** (its own ESP + root, UEFI/GPT). For a portable lobby, prefer a removable/EFI fallback-friendly layout.
7. Reboot, remove Drive 1 if desired, boot from **Drive 2** via UEFI boot menu. Drive 2 is now the portable lobby.

## Lobby system requirements (minimal)

- Non-`linux-libre` kernel + `linux-firmware` (maximize hardware support for unknown machines). **No Secure Boot** assumptions for now. **No encryption** assumptions for now.
- UEFI-bootable image with fallback `EFI/BOOT/BOOTX64.EFI`.
- Tools: `util-linux` (`lsblk`, `blkid`, `findmnt`, `mount`), `e2fsprogs`, `dosfstools`, `parted`/`gptfdisk`, `efibootmgr`, `pciutils`, `usbutils`, `iproute2`/basic networking as needed, `openssh` optional. Add `cryptsetup` only if encryption is introduced later.
- Keep it **declarative** (e.g. future `guix/operating-systems/lobby.scm` in this repo). Build images with `guix system image`.

## Transplanted NVMe workflow (from lobby)

Use stable identifiers recorded in `ubuntu-mini-pc/MACHINE.md` (do **not** rely on `/dev/nvme0n1` numbering):

- `by-id`: `nvme-WD_BLACK_SN7100_500GB_25463M803857*`, `nvme-eui.e8238fa6bf530001001b448b4fb20a70*`
- Root UUID `527ee6c7-f4f1-4e92-b0f8-02a0be6161c8` (ext4), ESP UUID `83FB-4733` (vfat)
- `fstab` on the Ubuntu install uses UUIDs (portable for mounting).

Typical repair loop (conceptual): mount root+ESP → bind `/dev,/proc,/sys,/run` → `chroot` → `update-initramfs -u -k all` → ensure correct microcode/drivers for target hardware → `update-grub` / reinstall bootloader to the intended ESP if needed → exit and reboot-test.

## Portable data layer (future)

Separate from the lobby: a mountable data partition (USB SSD or, later, SD with speed tradeoff) for carry-along data — e.g. local repos, reference images, host-agnostic configs/wallpapers. Prefer mounting as `/qimono/` (or a labeled mount) rather than replacing the host `/home`. Use **ext4** (or another POSIX fs) when Unix permissions/symlinks/xattrs matter; avoid exFAT for that role. Mount by **UUID/label**, not device node.

## Safety / open points

- Always verify target disk identity before install/format/`dd` (model, size, serial/WWN/UUID/label).
- Cheap/fake-capacity removable media: validate with `f3probe` before trusting for important roles.
- Lobby speed matters for repair work; USB SSD >> thumbdrive >> SD.
- Secure Boot, encryption, and cross-arch (ARM64) lobby images are out of scope for this first iteration.
