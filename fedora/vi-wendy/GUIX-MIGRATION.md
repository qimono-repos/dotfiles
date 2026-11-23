# Guix System first-citizen migration — vi-wendy

Goal: make GNU Guix System the primary OS on `vi-wendy`, replacing the legacy Fedora 35 eMMC install. The user has explicitly accepted a destructive migration and confirmed there is no personal information on this laptop.

Nothing destructive has been done yet. No disk has been erased, partitioned, or flashed. This document records the staged installer assets and the exact next gate before flashing.

## Host facts

- Architecture: `x86_64`.
- CPU: Intel Atom x5-Z8350, 4 cores.
- RAM: 3.7 GiB.
- Internal disk: `mmcblk0`, 29.1 GB eMMC.
- Firmware: UEFI, Secure Boot disabled.
- Current root: `/dev/mmcblk0p3`, Fedora 35 Workstation.
- AC power: connected during download; battery state `charging`, warning `none`.
- Observed unplugged discharge before AC: about 5.0–6.0 W, estimated full runtime about 7.4 h. No rapid-discharge evidence.

## Staged installer assets

### Balena Etcher

- Version: `2.1.9`, official Linux x64 ZIP from `balena-io/etcher`.
- Download: `https://github.com/balena-io/etcher/releases/download/v2.1.9/balenaEtcher-linux-x64-2.1.9.zip`.
- SHA256: `21ac9eb72a3f4d737623f85fc5ddd4073febb08b40e601b8051e99634da4fb09` — verified.
- Local ZIP: `~/Downloads/guix-migration/balenaEtcher-linux-x64-2.1.9.zip`.
- Installed directory: `~/.local/opt/balena-etcher-2.1.9/`.
- Launcher: `~/.local/bin/balena-etcher`.
- The broken `balenaEtcher` symlink inside the official ZIP was repointed to the bundled `balena-etcher` binary.
- A headless `--version` check reached the Electron/GUI startup path; no Etcher process was left running.

### GNU Guix System ISO

- Release: `1.5.0`, stable, x86_64 Linux.
- URL: `https://ftp.gnu.org/gnu/guix/guix-system-install-1.5.0.x86_64-linux.iso`.
- Resumed/downloaded through `ftpmirror.gnu.org` after the primary GNU FTP mirror was slow.
- Local ISO: `~/Downloads/guix-migration/guix-system-install-1.5.0.x86_64-linux.iso`.
- Size: 1,188,261,888 bytes.
- SHA256: `107e0a8082f03a10b15c1fb9383d2d752c1cdeda41b8db575a15550e1c2d8b4a` — verified.
- Detached signature: `~/Downloads/guix-migration/guix-system-install-1.5.0.x86_64-linux.iso.sig` — verified with GPG.
- Signer: Efraim Flashner, key fingerprint `A28B F40C 3E55 1372 662D 14F7 41AA E7DC CA3D 8351`.
- Signer key source from the release announcement: `https://codeberg.org/efraim.gpg`.

Note: an earlier search snippet misaligned the release checksums. The correct x86_64 system-install ISO checksum is the `107e0a…` value above, confirmed from the release announcement and by direct `sha256sum`.

## Current USB check

- The stick plugged in on 2026-11-22 is `/dev/sda`, SanDisk 3.2Gen1, 114.6 GiB, with one FAT partition `/dev/sda1` labeled `QI-DRIVE`.
- Its content is Windows ARM64 installation media: `setup.exe`, `sources/install.swm`, `bootmgr.efi`, and only `efi/boot/bootaa64.efi`.
- It is **not** Guix media, is wrong-architecture for this x86_64 Atom, and must be preserved for other machines.
- No write was performed to it. Another USB stick or SSD is needed for the Guix flash target.

## Gate before flashing

Do not flash until the target USB device is identified and confirmed.

1. Insert the intended USB stick, at least 2 GB.
2. Run `lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL` and identify the new device, for example `sda` or `sdc`.
3. Confirm the target is **not** `mmcblk0`; that is the internal eMMC and would destroy the current Fedora install.
4. Launch `balena-etcher`, select the staged ISO, select the confirmed USB device, and flash.
5. Boot from the USB stick via the firmware boot menu with Secure Boot disabled.
6. Use the Guix System installer to install onto the internal eMMC only after the installer's own device confirmation.

## Recovery notes

- Until the Guix installer overwrites it, Fedora remains on `mmcblk0`.
- `too` and `powerofff` are bash functions for immediate reboot/poweroff; see [`TOO.md`](./TOO.md).
- The battery monitor user service survives logout because linger is enabled; see [`BATTERY-MONITOR.md`](./BATTERY-MONITOR.md).
- If the red battery LED flickers but `upower` reports `state: charging`, `online: yes`, and `warning-level: none`, trust `upower` and keep AC connected during flashing/install.
