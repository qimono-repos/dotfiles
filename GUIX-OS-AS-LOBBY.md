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
1. Boot the machine from **Drive 1** (UEFI boot menu → removable/SD). The Guix image is a hybrid ISO; pick the **UEFI** entry for the removable device when shown. **Boot-menu key (this mini-pc is unknown/generic DMI, AMI BIOS 5.19 2023-09-11):** try `Esc`, `F7`, `F11`, `F12`, or `Del/F2` for setup; common AMI keys vary by OEM. From Linux you can also try `systemctl reboot --firmware-setup` to enter UEFI setup directly.
2. Expect the **Guided Graphical Installation** to be a **text-based ncurses/TUI** (dialog boxes) — *not* a Calamares/Qt GUI. TTY1 is the installer; root shells are available on other TTYs (`Ctrl+Alt+F3`…`F6`), docs on `Ctrl+Alt+F2`. You can also choose manual installation.
3. In the installer, identify **Drive 2** by model/size/label (`qi-thumb`, 14.5G, `USB DISK 2.0`) — **not** `nvme0n1`. Verify with `lsblk -o NAME,MODEL,SIZE,TRAN,LABEL,FSTYPE,UUID` before partitioning.
4. Run the guided install / `guix system install` targeting **Drive 2 only** (its own ESP + root, UEFI/GPT). For a portable lobby, prefer the removable/EFI fallback-friendly layout.
5. Reboot, remove Drive 1 if desired, boot from **Drive 2** via UEFI boot menu. Drive 2 is now the portable lobby.

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
