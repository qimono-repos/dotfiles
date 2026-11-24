# Guix System first-citizen migration — vi-wendy

Goal: make GNU Guix System the primary OS on `vi-wendy`, replacing the legacy Fedora 35 eMMC install. The user has explicitly accepted a destructive migration and confirmed there is no personal information on this laptop.

No disk has been erased by the agent. The user has explicitly authorized wiping the current `QI-DRIVE` USB stick and using it for the Guix installer; flash completion is still unconfirmed. This document records the staged installer assets, the next gates, and installer networking workarounds.

## Host facts

- Architecture: `x86_64`.
- CPU: Intel Atom x5-Z8350, 4 cores.
- RAM: 3.7 GiB.
- Internal disk: `mmcblk1`, 29.1 GB eMMC. Older notes used `mmcblk0`; the kernel renamed it after reboot.
- Firmware: UEFI, Secure Boot disabled.
- Current root: `/dev/mmcblk1p3`, Fedora 35 Workstation.
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
- Its content was Windows ARM64 installation media: `setup.exe`, `sources/install.swm`, `bootmgr.efi`, and only `efi/boot/bootaa64.efi`.
- It was initially preserved, but the 2026-11-23 directive supersedes that: the user explicitly authorized wiping this stick and using it as the Guix installer.
- Etcher was relaunched successfully through a GNOME desktop launcher, but flash success has not been verified.
- When flashing, target the whole `/dev/sda`, not `/dev/sda1`, and never the internal `/dev/mmcblk1`.

## Gate before flashing

Do not flash until the target USB device is identified and confirmed.

1. Insert the intended USB stick, at least 2 GB.
2. Run `lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,MODEL` and identify the new device, for example `sda` or `sdc`.
3. Confirm the target is **not** `mmcblk1`; that is the internal eMMC and would destroy the current Fedora install.
4. Unmount any mounted partition on the target, such as `/run/media/wendy/QI-DRIVE`.
5. Launch `balena-etcher`, select the staged ISO, select the confirmed whole USB device, and flash.
6. Boot from the USB stick via the firmware boot menu with Secure Boot disabled.
7. Use the Guix System installer to install onto the internal eMMC only after the installer's own device confirmation.

## Installer networking without Ethernet

- `vi-wendy` has Wi-Fi but no LAN port and no USB-to-LAN adapter is currently available.
- The goal is to bring up `wlan0` from the Guix installer shell; no Ethernet is required if the Wi-Fi firmware loads.
- The Wi-Fi hardware is Realtek `rtl8723bs` on SDIO; Fedora uses staging driver `r8723bs` and loads nonfree firmware `rtlwifi/rtl8723bs_nic.bin`.
- The staged official Guix ISO contains `wpa_supplicant`, `wpa_passphrase`, `dhclient`, `iwlist`, and the `r8723bs` staging module, but no visible `rtl8723bs_nic.bin` firmware. If previous `wpa_supplicant` attempts failed, the likely cause is that there was no usable `wlan0`, not that `wpa_supplicant` is absent.

First diagnose from the Guix installer shell:

```sh
ip -o link
rfkill list
dmesg | grep -Ei 'r8723bs|firmware|wlan'
```

If `wlan0` exists, configure Wi-Fi:

```sh
rfkill unblock all
ip link set wlan0 up
wpa_passphrase 'SSID' > /tmp/guix-wifi.conf
wpa_supplicant -B -i wlan0 -c /tmp/guix-wifi.conf
dhclient -v wlan0
ping -c 3 guix.gnu.org
```

`wpa_passphrase` prompts for the password, so the secret is not placed in shell history. Do not store the passphrase in this repository.

If `wlan0` does not exist, try loading the staging driver:

```sh
modprobe r8723bs
ip -o link
dmesg | grep -Ei 'r8723bs|firmware|wlan'
```

If it still does not exist, the official Guix ISO is missing the nonfree firmware. The clean Wi-Fi fix is a Nonguix installer image or another Guix image that includes `rtlwifi/rtl8723bs_nic.bin`; then repeat the `wpa_supplicant` steps. Phone USB tethering remains a fallback, not the preferred path, because it avoids the Wi-Fi firmware problem entirely.

## Recovery notes

- Until the Guix installer overwrites it, Fedora remains on `mmcblk1`.
- `too` and `powerofff` are bash functions for immediate reboot/poweroff; see [`TOO.md`](./TOO.md).
- The battery monitor user service survives logout because linger is enabled; see [`BATTERY-MONITOR.md`](./BATTERY-MONITOR.md).
- If the red battery LED flickers but `upower` reports `state: charging`, `online: yes`, and `warning-level: none`, trust `upower` and keep AC connected during flashing/install.
