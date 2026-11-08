# Guix Lobby: Manual TTY Install (step-by-step, photo-friendly)

**Purpose:** install a minimal Guix “lobby” onto a USB thumbdrive (`qi-keydrive`) when the **Guided TUI disk picker hides it** (“installation device as well as the small devices are filtered”).  
**Context (this iteration):** boot from Guix 1.5.0 installer on micro SD; install to 7.5G `VendorCo ProductCode` labeled `qi-keydrive`; **never touch** `nvme0n1` (WD_BLACK SN7100 / Ubuntu).  
**Difficulty:** moderate (Arch-like manual steps). Go slowly. **Do not type commands that target `nvme0n1`.**

> **Using a phone LLM (ChatGPT) with photos:** take clear photos of (1) `lsblk` output, (2) any error, (3) your `cfdisk`/partition screen before writing. Ask it to confirm **which disk is the target** before you run destructive commands.

---

## 0) Before you start
- [ ] **LAN cable plugged in** if possible (fastest/reliable). Guix install usually downloads substitutes.
- [ ] Guix installer booted from the **micro SD** (UEFI). You can see the ncurses TUI.
- [ ] **Both** removable drives plugged in as intended (SD = installer/source, thumbdrive = target), but you will identify by **model/size/label**, not by `/dev/sdX` letter.
- [ ] Know the *forbidden* disk: **`WD_BLACK SN7100 500GB` / `nvme0n1`** = your Ubuntu system. **Never partition, format, mount as target, or `guix system init` to it.**

## 1) Open a root shell (TTY)
1. On the Guix installer screen, press **`Ctrl+Alt+F3`** (try **F4–F6** if needed).
2. Log in as **`root`** (installer live environment commonly has no password; if asked, try empty/just Enter).
3. To go back to the TTY installer: **`Ctrl+Alt+F1`**. Docs: **`Ctrl+Alt+F2`**.

## 2) Identify disks (MOST IMPORTANT)
Run:
```sh
lsblk -o NAME,MODEL,SIZE,TYPE,TRAN,LABEL,FSTYPE,UUID,MOUNTPOINT
```
**What you want to find (this iteration):**
| Role | How to recognize | Example (letters may differ!) |
|---|---|---|
| **TARGET (lobby)** | Model **`ProductCode`** (vendor `VendorCo`), size **~7.5G**, often label **`qi-keydrive`** | `sdX` disk, ~7.5G, usb |
| **SOURCE (installer)** | Guix ISO / micro SD reader, may show `GUIX...` labels | do **not** overwrite |
| **FORBIDDEN** | **`WD_BLACK SN7100 500GB`**, size ~465.8G, `nvme0n1` | **never touch** |

Use `<target_disk>` for a device-path placeholder in documentation (for example, `/dev/sda`). In executable shell snippets, bind the device path to the `TARGET_DISK` variable. For this installation, the identified target is `/dev/sda`.

If unsure: **stop and take a photo of `lsblk`**.

## 3) (If needed) confirm you’re on UEFI
```sh
[ -d /sys/firmware/efi ] && echo UEFI || echo BIOS
```
Expect **UEFI**.

## 4) Network check (recommended)
```sh
ip -br a
ping -c1 gnu.org
```
If no network and you can: **plug a LAN cable**, then retry. (Wi‑Fi setup varies in the live image; LAN is the easy path.)

## 5) Partition the TARGET disk (UEFI/GPT, 2 partitions)
These commands operate on the target device. Set `TARGET_DISK` to the device path corresponding to `<target_disk>`.

```sh
TARGET_DISK=/dev/sda

# unmount target partitions if mounted
umount "${TARGET_DISK}"[0-9]* 2>/dev/null || true

# optional but clear
wipefs -a "$TARGET_DISK"

# interactive partitioner (recommended)
cfdisk "$TARGET_DISK"
```
In `cfdisk`:
1. Select **`gpt`** label type if asked.
2. Delete any existing partitions on **this disk only**.
3. New partition **#1**: size **`512M`**, type **`EFI System`** (ESP).
4. New partition **#2**: use **remaining space**, type **`Linux filesystem`**.
5. **`[ Write ]`** → type `yes` → **`[ Quit ]`**.

If `cfdisk` isn’t usable, `parted` alternative:
```sh
parted -s "$TARGET_DISK" mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB set 1 esp on \
  mkpart LOBBY ext4 513MiB 100%
```

Verify:
```sh
lsblk -o NAME,MODEL,SIZE,TYPE,LABEL,FSTYPE "$TARGET_DISK"
```
Expect 2 partitions under the **7.5G ProductCode** disk.

## 6) Format partitions
`TARGET_DISK` remains the shell variable from Step 5. For USB `/dev/sdX` devices, append `1` for EFI and `2` for the root partition (for example, `/dev/sda1` and `/dev/sda2`).
```sh
mkfs.fat -F32 -n EFI "${TARGET_DISK}1"
mkfs.ext4 -F -L qi-keydrive "${TARGET_DISK}2"
```

## 7) Mount target filesystems
```sh
mount "${TARGET_DISK}2" /mnt
mkdir -p /mnt/boot/efi
mount "${TARGET_DISK}1" /mnt/boot/efi
findmnt /mnt /mnt/boot/efi
```
Confirm `/mnt` is on the **7.5G/qi-keydrive** disk and `/mnt/boot/efi` is the EFI partition — **not nvme**.

## 8) Enable copy-on-write store (Guix installer)
```sh
herd start cow-store /mnt
```
(If `herd`/service differs or errors, note the message and continue only if you understand it; on the Guix installer this is normally needed.)

## 9) Download the minimal system configuration from GitHub
The Guix lobby operating-system definition is maintained in [`lobby-files/config.scm`](./lobby-files/config.scm).

Fetch it directly into the mounted target:

```sh
mkdir -p /mnt/etc
curl -fL https://raw.githubusercontent.com/qimono-repos/dotfiles/main/lobby-files/config.scm -o /mnt/etc/config.scm
```

If `curl` isn't installed in the live environment, use `wget`:

```sh
wget -O /mnt/etc/config.scm https://raw.githubusercontent.com/qimono-repos/dotfiles/main/lobby-files/config.scm
```

Read the embedded version and change summary after every download:

```sh
head -n 3 /mnt/etc/config.scm
```

Current version: `v1.0.2`. The first line should read `;; QIMONO-LOBBY-CONFIG-VERSION: v1.0.2`. This identifies which version reached the installer after each `wget` or `curl`.

Use semantic versioning for `config.scm`: increment PATCH for corrections (including comment-only edits), MINOR for new capabilities or services, and MAJOR for incompatible configuration changes. Every edit to this file must increment the version and update its `Change:` comment, including during rapid troubleshoot → commit → download → retry loops.

The configuration retains the original minimal lobby setup: removable UEFI GRUB, `qi-keydrive` root and `EFI` ESP labels, user `qi`, SSH, and DHCP. Edit the version-controlled file in the repository for future changes instead of retyping Scheme in the installer.

## 10) Initialize the system (this takes time)
```sh
guix system init /mnt/etc/config.scm /mnt
```
- Needs network for substitutes; may take a while.
- **If it fails with “No space left on device”:** the 7.5G target may be too small for this image/config. That’s a real capacity limit (not the TUI filter) — use a larger USB drive/SSD for Drive 2.
- **If it fails otherwise:** photo the last ~30 lines and the exact error.

## 11) Passwords are initialized after the first boot
No `chroot` step is needed. A fresh Guix System has no conventional `/bin/sh` in its root filesystem, so `chroot /mnt /bin/sh -c 'passwd root'` fails with `No such file or directory`. Guix's installation manual specifies setting user passwords after booting the installed system, starting with `root` (initially empty password).

## 12) Reboot into the lobby
```sh
sync
umount -R /mnt
reboot
```
Remove the **SD installer** if convenient. Use the machine’s **UEFI boot menu** (`Esc`/boot menu; or BIOS priority) and pick the **`qi-keydrive` / ProductCode / USB thumbdrive (UEFI)** entry. **Do not boot the NVMe** unless you intend to return to Ubuntu.

## 13) After first boot: initialize passwords
At the Guix console, log in as `root`. Its password is initially empty; press Enter if asked for one.

```sh
passwd root
passwd qi
```

Each `passwd` command prompts interactively for the new password and confirmation.

Then, if you want to check network and Guix version:

```sh
ip -br a
guix --version
```

Reference: [GNU Guix manual, Proceeding with the Installation](https://guix.gnu.org/manual/en/html_node/Proceeding-with-the-Installation.html).

---

## Common mistakes / safety checklist
- [ ] Target matched by **`ProductCode` + ~7.5G (+ `qi-keydrive`)**, not by `/dev/sdX` letter alone.
- [ ] **`nvme0n1` / WD_BLACK never touched.**
- [ ] ESP mounted at `/mnt/boot/efi`, root at `/mnt`, before `guix system init`.
- [ ] LAN available (or you knowingly handled Wi‑Fi).
- [ ] If 7.5G is truly too small, the fix is a **larger USB SSD/thumbdrive**, not faking size.

## Related
- Design/notes: [`GUIX-OS-AS-LOBBY.md`](./GUIX-OS-AS-LOBBY.md)
- NVMe identity (this fleet): `ubuntu-mini-pc/MACHINE.md`
