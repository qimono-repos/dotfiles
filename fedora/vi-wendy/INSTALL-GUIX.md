# Install Guix System on `vi-wendy` — critical-moment runbook

This is the standalone install card for this machine. Use it when there is no assistant available. It covers flashing, boot, Wi‑Fi, Nonguix fallback, disk targeting, and the most likely gotchas.

Status: the user has explicitly authorized destructive migration of this laptop and wiping the current `QI-DRIVE` USB stick for the Guix installer. No personal data is expected on the laptop. Do **not** use these instructions on another machine without re-checking every device name.

Important clarification (2026-11-23 live-installer evidence): Wi-Fi works under Fedora. The **official Guix installer DID expose `wlan0`**, initially `DOWN`, while `rfkill` reported **soft blocked: yes / hard blocked: no**. Its kernel also reported `hci0: Missing Free firmware (non-Free firmware loading is disabled)`, plus a Realtek Bluetooth firmware failure and missing Intel SOF audio firmware. Those displayed firmware errors specifically name Bluetooth/audio; the Wi-Fi firmware diagnosis comes from the known RTL8723BS hardware and Fedora's working firmware. **An interface existing does not establish that Wi-Fi can actually initialize or associate.** **The Nonguix installer has now successfully brought `wlan0` online and reached `www.gnu.org` (4/4 replies, 0% packet loss).**

## Critical command bundle

Run this first inside the Guix installer shell and keep the output:

```sh
ip -o link; rfkill list; dmesg | grep -Ei 'r8723bs|firmware|wlan'
```

Interpretation:

- A usable Wi‑Fi interface such as `wlan0`, `wlp2s0`, or similar must appear in `ip -o link` before `wpa_supplicant` can work.
- If no wireless interface appears, the problem is driver/firmware, not the Wi‑Fi password.
- This machine uses Realtek `rtl8723bs` SDIO Wi‑Fi. Fedora loads nonfree firmware `rtlwifi/rtl8723bs_nic.bin`. The official Guix ISO has `wpa_supplicant` tools and the `r8723bs` staging module, but no visible `rtl8723bs_nic.bin` firmware.
- If `wlan0` is present but radio activation or association fails, inspect the kernel messages; a visible interface is not proof of functioning firmware. Switch to Nonguix when the stock Linux-libre environment cannot initialize the radio.

## 0. Before the critical moment

- Plug in AC power. Do not install or flash on battery.
- Have the Wi‑Fi SSID and passphrase available, but do not write the passphrase into this repo or chat.
- Decide which image to boot:
  - Official Guix 1.5.0 ISO: already staged, libre kernel, likely missing this Wi‑Fi firmware.
  - Nonguix x86_64 installer image: **selected path after the 2026-11-23 attempt**; uses the standard Linux kernel and makes nonfree firmware available.
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
- If `wlan0` is shown but remains unusable, note whether `ip link set wlan0 up` fails and inspect recent `dmesg` messages; then use section 6.

## 5. Wi‑Fi path when a wireless interface exists

**Nonguix live test: SUCCESS.** After `rfkill unblock wifi`, `ip link set wlan0 up`, `wpa_passphrase` and `wpa_supplicant`, `dhclient -v wlan0` received a DHCP lease and `ping www.gnu.org` returned 4/4 replies (0% loss). The `wpa_cli` control-socket query did report `No such file or directory`, but it did not prevent Wi-Fi connection, DHCP or DNS resolution; investigate its monitoring socket separately, not as proof that connection failed.



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

## 6. Firmware diagnosis and Nonguix installation route (Wi-Fi confirmed; installation next)

### Confirmed Nonguix installer result (subsequent live session)

- `iwlist wlan0 scanning` discovered wireless networks.
- `wpa_supplicant` initialized and the laptop associated successfully.
- `dhclient -v wlan0` acquired a DHCP address.
- `ping www.gnu.org`: four responses, zero packet loss.
- No network credential, Wi-Fi SSID, generated PSK or local IP is recorded in this public runbook.
- Next phase: install onto the internal eMMC, retaining the Nonguix Linux kernel and necessary firmware in the **installed** operating-system configuration.

### What the official installer actually reported on 2026-11-23

```text
2: wlan0: <BROADCAST,MULTICAST> ... state DOWN
rfkill: Wireless LAN / Soft blocked: yes / Hard blocked: no
hci0: Missing Free firmware (non-Free firmware loading is disabled)
Bluetooth: hci0: RTL: firmware file /(DEBLOBBED)/ not found
sof-audio-acpi-intel-byt: SOF firmware and/or topology file not found
r8723bs: module is from the staging directory
```

Interpretation:

- `wlan0` exists. This **does not** mean Wi-Fi is operational; the radio was soft-blocked and the Realtek staging module was present.
- `rfkill unblock wifi` clears a software radio block. It does **not** enable restricted firmware loading.
- The message about non-Free firmware loading reflects the Linux-libre kernel's firmware policy. There is **no ordinary `rfkill` command, kernel parameter or runtime toggle** that converts the official installer into a nonfree-firmware-capable Linux kernel.
- The explicit firmware errors visible above involve Bluetooth and Intel audio. The Wi-Fi chipset is RTL8723BS; Fedora uses `rtlwifi/rtl8723bs_nic.bin`. If Wi-Fi initialization fails on the official installer, a firmware-capable kernel plus that firmware is the practical path.
- The installed Guix System requires its **own** nonfree kernel/firmware configuration. Booting a Nonguix installation image alone does not guarantee wireless networking after installation.

### Selected sequence: Nonguix x86_64 installer → full Guix System

1. Download a **Nonguix x86_64 installation image** from the [Nonguix project](https://gitlab.com/nonguix/nonguix) / its [releases](https://gitlab.com/nonguix/nonguix/-/releases). Choose an installer image, not a boot image for a different architecture. Record the image filename and its published checksum, when available.
2. Flash that image with Balena Etcher onto the **whole** `QI-DRIVE` USB device. The known Fedora-era USB was `/dev/sda` (114.6 GiB); the internal eMMC was `/dev/mmcblk1` (29.1 GB, `HBG4a2`). Etcher's selected drive must be the USB, not the eMMC.
3. Reboot vi-wendy into the Nonguix USB installer and open its shell.
4. Bring up the radio and inspect its status:
   ```sh
   rfkill unblock wifi
   ip link set wlan0 up
   ip -br link show wlan0
   dmesg | grep -Ei 'r8723bs|rtl8723bs|firmware|wlan'
   ```
   If the interface is named differently, replace `wlan0` with the actual name from `ip -o link`.
5. Authenticate to Wi-Fi and obtain DHCP using **section 5**. Verify connectivity with both an IP address and a DNS hostname.
6. Install Guix onto vi-wendy's internal **29.1 GB `HBG4a2` eMMC**, replacing Fedora, following section 7's disk mapping and the chosen installer flow.
7. Before the installer's final system-generation step, ensure its `operating-system` definition uses the standard Nonguix `linux` kernel and compatible firmware (in particular the RTL8723BS firmware, supplied by the selected firmware package). The Nonguix channel must be available to evaluate those package references. Verify that the selected configuration actually includes these components rather than assuming the installer image automatically supplies them to the installed system.
8. Boot the installed system from eMMC, not the USB. Confirm `wlan0`, firmware loading and Wi-Fi connectivity again after the first reboot.

Firmware-capable Guix System configurations generally add `(nongnu packages linux)` and `(nongnu system linux-initrd)` imports and configure `(kernel linux)`, `(initrd microcode-initrd)`, and appropriate `(firmware ...)` packages. The exact Scheme should be derived from the Nonguix installer/channel version in use; do not blindly paste an unverified configuration into the final system.

### Alternative: phone USB tethering

USB tethering can provide temporary internet access when the current live installer cannot associate over Wi-Fi. It does **not** enable the Realtek Wi-Fi firmware in the installed OS.

```sh
ip -o link
# Set IFACE to the USB networking interface discovered above:
IFACE=usb0
ip link set "$IFACE" up
dhclient -v "$IFACE"
ip addr show "$IFACE"
ping -c 3 guix.gnu.org
```

Replace `usb0` with the actual interface name.

## One-command full-house deployment (Nonguix live shell)

With the verified Nonguix Wi-Fi connection active, the integrated installer lives at
[`fedora/vi-wendy/guix/install-guix.sh`](./guix/install-guix.sh), backed by
[`config.scm`](./guix/config.scm).

It installs **Guix System** to the internal HBG4a2 eMMC, not a USB lobby. The
installed identity is **hostname `Qimono`**, login **`qi`**, StumpWM (Common Lisp),
SLiM, NetworkManager, and standard Nonguix Linux/firmware.

From the **root** shell already inside
`~/source/repos/qimono-repos/dotfiles/fedora/vi-wendy/guix`, use the Git
workflow. First test channel bootstrapping and config evaluation only:

```sh
git pull --ff-only origin main &&
  QIMONO_PREFLIGHT_ONLY=1 bash ./install-guix.sh
```

Only after the preflight succeeds, run the actual install:

```sh
bash ./install-guix.sh
```

The script now **prefers sibling `config.scm` and `channels.scm` files from
the Git checkout**. It downloads these from GitHub only when the sibling files
are absent. Git pulls become the normal update mechanism.

The script identifies the HBG4a2 internal eMMC by model and capacity, evaluates
the versioned Guix configuration before partitioning, sets up
EFI + swap + root, builds the operating system, configures first-boot
NetworkManager from the local Wi-Fi configuration when available, and prints the
first-boot instructions. Re-running it with matching Qimono filesystem labels
reuses the partitions rather than formatting again.

### Failure history and corrected channel source (2026-11-24)

1. The first attempt stopped before partitioning because the live Guix
   command lacked the `(nongnu packages linux)` module.
2. The next version downloaded the authenticated Nonguix channel, then
   `guix pull` stopped at:
   ```text
   guix pull: error: Git error: cannot redirect from 'git.savannah.gnu.org'
                     to 'https://git.savannah.gnu.org'
   ```
   This was **not a partitioning error**. The script had still not
   formatted or repartitioned the HBG4a2 eMMC.

GNU Guix migrated its Git repository to Codeberg in May 2025; the
Guix 1.5.0 live installer inherited a Savannah URL. The authenticated
`channels.scm v1.1.0` now uses `https://codeberg.org/guix/guix.git`
for the official Guix channel, while inheriting the original channel
introduction. Nonguix remains authenticated via its published fingerprint.

`install-guix.sh v1.2.0` uses the sibling config and channel files
from the Git checkout. It authorizes the Nonguix substitute server,
runs `guix pull` with one build job and core, runs the pulled Guix
binary, and performs a `guix system build --dry-run` evaluation **before
destructive partitioning**. The preflight can still fail due to downloads,
builds, or Scheme evaluation. A successful static CI check does not prove
the target can complete a Guix pull.

Hardware from the successful preflight: internal HBG4a2 eMMC was
`/dev/mmcblk2` (29 GiB) on that boot. Script matches model and size rather
than hardcoding this device node.

Current source revisions: `config.scm v1.1.3`;
`install-guix.sh v1.2.0`; `channels.scm v1.1.0`.
Static CI checks live in
[`vi-wendy-guix-checks.yml`](../../.github/workflows/vi-wendy-guix-checks.yml).
Guix evaluation/build on the laptop remains the integration test.

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
- Official Guix 1.5.0 exposed `wlan0` in the live test, but that alone did not prove the radio was usable. Linux-libre disables nonfree firmware loading.
- Nonguix is the next selected installer for the RTL8723BS hardware; verify radio operation there. Installed-system Wi-Fi still requires the right Nonguix kernel/firmware configuration.
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
