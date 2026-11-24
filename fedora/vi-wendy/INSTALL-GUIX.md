# Install Guix System on `vi-wendy` — critical-moment runbook

This is the standalone install card for this machine. Use it when there is no assistant available. It covers flashing, boot, Wi‑Fi, Nonguix fallback, disk targeting, and the most likely gotchas.

Status: the user has explicitly authorized destructive migration of this laptop and wiping the current `QI-DRIVE` USB stick for the Guix installer. No personal data is expected on the laptop. Do **not** use these instructions on another machine without re-checking every device name.

Important clarification: Wi‑Fi hardware works on this laptop right now under Fedora. This runbook is **not** claiming the laptop has no Wi‑Fi, that the credentials are wrong, or that the router is unavailable. The narrower problem is that the official Guix installer uses the libre kernel and may not load the nonfree Realtek firmware that Fedora already loads. The same hardware can therefore work in Fedora and still show no `wlan0` inside the official Guix installer.

## Critical command bundle

Run this first inside the Guix installer shell and keep the output:

```sh
ip -o link; rfkill list; dmesg | grep -Ei 'r8723bs|firmware|wlan'
```

Interpretation:

- A usable Wi‑Fi interface such as `wlan0`, `wlp2s0`, or similar must appear in `ip -o link` before `wpa_supplicant` can work.
- If no wireless interface appears, the problem is driver/firmware, not the Wi‑Fi password.
- This machine uses Realtek `rtl8723bs` SDIO Wi‑Fi. Fedora loads nonfree firmware `rtlwifi/rtl8723bs_nic.bin`. The official Guix ISO has `wpa_supplicant` tools and the `r8723bs` staging module, but no visible `rtl8723bs_nic.bin` firmware.
- If the official ISO gives no `wlan0`, use a Nonguix/firmware-capable installer image, or use phone USB tethering as a fallback.

## 0. Before the critical moment

- Plug in AC power. Do not install or flash on battery.
- Have the Wi‑Fi SSID and passphrase available, but do not write the passphrase into this repo or chat.
- Decide which image to boot:
  - Official Guix 1.5.0 ISO: already staged, libre kernel, likely missing this Wi‑Fi firmware.
  - Nonguix installer image: preferred if official ISO has no `wlan0`; includes full Linux kernel and firmware support.
- Keep this file open or printed.
- Accept that this install replaces Fedora on the internal eMMC.
- Remember: `too` and `powerofff` do **not** exist in the Guix installer. Use `reboot` or `poweroff`.

## 1. Staged assets on Fedora

```bash
ls -lh ~/Downloads/guix-migration/guix-system-install-1.5.0.x86_64-linux.iso
sha256sum ~/Downloads/guix-migration/guix-system-install-1.5.0.x86_64-linux.iso
```

Expected SHA256:

```text
107e0a8082f03a10b15c1fb9383d2d752c1cdeda41b8db575a15550e1c2d8b4a
```

Etcher:

```bash
~/.local/bin/balena-etcher
```

Expected Etcher SHA256:

```text
21ac9eb72a3f4d737623f85fc5ddd4073febb08b40e601b8051e99634da4fb09
```

## 2. Flash the USB stick

Check devices before writing:

```bash
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,MODEL
```

Current known devices before flashing from Fedora:

- Internal eMMC: `/dev/mmcblk1`, about 29.1 GB, model `HBG4a2`. This is the install target after boot, not the flash target.
- USB stick to wipe: currently `/dev/sda`, about 114.6 GB, partition `/dev/sda1`, label `QI-DRIVE`.
- The old `QI-DRIVE` content was Windows ARM64 installation media. The user authorized wiping it.

Flash gates:

1. Select the staged Guix ISO, not the Etcher ZIP.
2. Select the whole USB device, not `/dev/sda1`.
3. Never select `/dev/mmcblk1` or any 29.1 GB device when flashing.
4. Etcher needs a GUI admin password. This must be entered by the person at the keyboard.
5. After flashing, if the stick still shows `QI-DRIVE` and Windows ARM64 files, the flash did not happen; repeat the flash.

## 3. Boot the installer

- Reboot and use the firmware boot menu.
- Secure Boot is already disabled on this laptop; keep it disabled.
- Select the USB installer entry.
- Choose the keyboard/language prompts.
- Choose the **shell-based installer** path when possible. It gives direct control over Wi‑Fi before installation.
- In the Guix installer shell, documentation may be available with `Alt-F2`.

If the graphical installer is already running but has no network, drop to a shell/terminal from the installer menu, bring up networking first, then return to the installer.

## 4. Network diagnosis inside the Guix installer

Run:

```sh
ip -o link
rfkill list
dmesg | grep -Ei 'r8723bs|firmware|wlan'
ifconfig -a
```

Useful interpretations:

- `rfkill` shows whether Wi‑Fi is soft-blocked or hard-blocked.
- `ip -o link` or `ifconfig -a` gives the interface name to use below.
- `dmesg` shows whether the driver loaded and whether firmware failed.
- If the interface name is long, use that exact name. Do not assume `wlan0`.
- If there is no wireless interface, go to section 6.

## 5. Wi‑Fi path when a wireless interface exists

Set `IFACE` to the exact interface name from `ip -o link`, for example `wlan0`.

```sh
IFACE=wlan0
rfkill unblock all
ip link set "$IFACE" up
printf 'ctrl_interface=/run/wpa_supplicant\n' > /tmp/guix-wifi.conf
wpa_passphrase 'YOUR_SSID' >> /tmp/guix-wifi.conf
mkdir -p /run/wpa_supplicant
wpa_supplicant -B -i "$IFACE" -c /tmp/guix-wifi.conf
wpa_cli -p /run/wpa_supplicant -i "$IFACE" status
dhclient -v "$IFACE"
ip addr show "$IFACE"
ip route
```

Check connectivity:

```sh
ping -c 3 8.8.8.8
ping -c 3 guix.gnu.org
```

Notes:

- `wpa_passphrase 'YOUR_SSID'` prompts for the passphrase; do not pass the password as a command argument.
- A `wpa_cli` status of `COMPLETED` is good.
- `4-WAY HANDSHAKE FAILED` usually means wrong passphrase or wrong security mode.
- If IP ping works but hostname ping fails, DNS is the remaining problem. Check:

```sh
cat /etc/resolv.conf
```

If needed, temporarily set a public resolver:

```sh
printf 'nameserver 1.1.1.1\n' > /etc/resolv.conf
ping -c 3 guix.gnu.org
```

If `wpa_supplicant` fails, retry once cleanly:

```sh
pkill -f wpa_supplicant
wpa_supplicant -i "$IFACE" -c /tmp/guix-wifi.conf -d
```

Capture the last error lines before trying anything else.

## 6. No wireless interface: driver/firmware path

Try loading the staging driver:

```sh
modprobe r8723bs
ip -o link
dmesg | grep -Ei 'r8723bs|firmware|wlan'
```

If `wlan0` or another wireless interface now exists, return to section 5.

If it still does not exist, the official Guix ISO is missing the nonfree firmware. Choose one of these workarounds:

### Workaround A — Nonguix installer image, preferred for Wi‑Fi

Reflash the USB with a Nonguix installer image that uses the full Linux kernel and firmware, boot it, then repeat sections 4 and 5.

Gotcha: a Nonguix **installer** does not automatically make the **installed system** nonfree. The installed Guix system still needs a system configuration that uses Nonguix/Linux firmware if Wi‑Fi must work after reboot.

### Workaround B — phone USB tethering, fallback only

Plug the phone into USB and enable USB tethering. The interface may be `usb0`, `enp0s20f0u1`, `enx...`, or similar.

```sh
ip -o link
IFACE=usb0
ip link set "$IFACE" up
dhclient -v "$IFACE"
ip addr show "$IFACE"
ping -c 3 guix.gnu.org
```

Replace `usb0` with the interface that appeared after tethering.

## 7. Disk target gate inside the installer

Before any installer action that erases a disk:

```sh
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT,MODEL
```

Rules:

- The internal eMMC is about 29.1 GB, model `HBG4a2`.
- Under Fedora it is `/dev/mmcblk1`, but the installer may name it differently. Select by size and model, not by remembered device name.
- The USB installer itself may be `/dev/sda` or another `sd*` device. Do not install onto it.
- Do not select any 114.6 GB SanDisk stick as the install target.
- Do not select a partition such as `mmcblk1p1` when the installer asks for a whole disk.
- The old warning in `MACHINE.md` and `QA/Checklist-User.md` said not to install onto eMMC; that was superseded by the user's explicit destructive-migration authorization.

Recommended install choice for this run:

- Replace Fedora on the internal 29.1 GB eMMC.
- Do not preserve Fedora unless you are deliberately doing manual partitioning.
- Keep the desktop modest; this host has only 3.7 GiB RAM and 29.1 GB storage.

If using the shell-based install manually:

- Follow the installer documentation available with `Alt-F2`.
- Start the cow store only after the target partitions are mounted:

```sh
herd start cow-store /mnt
```

- Run `guix system init` only when the target and config file are correct:

```sh
guix system init /path/to/config.scm /mnt
```

If already using the installer's own guided disk steps, do not hand-write `guix system init` unless the installer tells you to.

## 8. During installation

- Keep AC connected.
- Expect slow package downloads/builds on 3.7 GiB RAM and 2.4 GHz Wi‑Fi.
- If `guix pull` or substitutes fail, first re-check the network section.
- If an install fails partway through, the Guix store may already contain downloaded packages. Prefer resuming over wiping and starting from zero.
- Do not repeatedly reformat the eMMC after the same failure; capture the exact error first.
- If the installer asks for full-disk encryption, only enable it if you are prepared to enter that passphrase on every boot.

## 9. First boot after install

1. Remove the USB installer.
2. Boot from internal eMMC.
3. Confirm Guix boots, not Fedora and not the USB stick.
4. Re-run network diagnosis if Wi‑Fi does not work:

```sh
ip -o link; rfkill list; dmesg | grep -Ei 'r8723bs|firmware|wlan'
```

5. If the installed system has no `wlan0`, the installed system still lacks the Realtek firmware. The fix is a system configuration using Nonguix/Linux firmware, not more `wpa_supplicant` retries.
6. Do not enable `sshd` or promote this host to a server role after Guix installs. It remains a low-resource legacy laptop.

## 10. Gotchas checklist

- No LAN port and no USB-to-LAN adapter are available.
- Having Wi‑Fi hardware is not enough; the interface must exist before `wpa_supplicant` can work.
- `wpa_supplicant` failing is often a missing interface/firmware problem, not a password problem.
- The official Guix ISO has Wi‑Fi tools but likely lacks `rtl8723bs_nic.bin`.
- Nonguix installer fixes installer Wi‑Fi; installed-system Wi‑Fi still requires the right system config.
- Long interface names are normal; always copy the exact name from `ip -o link`.
- `mmcblk1` is the internal eMMC under Fedora; it may be renamed in the installer.
- The USB installer is not the target for `guix system init`.
- Etcher must target the whole USB disk, not its partition.
- User must type the GUI admin password; an assistant cannot do it.
- Do not commit SSID/passphrase or generated PSK hashes.
- `too` and `powerofff` are Fedora/bash helpers only; use `reboot` and `poweroff` in Guix.
- Keep AC power connected during flash and install.
- 3.7 GiB RAM and 29.1 GB eMMC make heavy builds unreliable.
- Broad firewall/port rules from Fedora do not carry over as a reason to enable services on Guix.
- If stuck, stop before destructive repetition and capture diagnostics.

## 11. If stuck, capture this

```sh
ip -o link
rfkill list
dmesg | grep -Ei 'r8723bs|firmware|wlan'
ip route
cat /etc/resolv.conf
```

Also note:

- The exact interface name from `ip -o link`.
- The exact `wpa_supplicant`, `dhclient`, or `guix` error line.
- Which image was booted: official Guix or Nonguix.
- Whether the installer showed a 29.1 GB `HBG4a2` disk.
- What device was selected as the install target before any erase.
- A photo of the screen is acceptable if typing the output is impractical.
