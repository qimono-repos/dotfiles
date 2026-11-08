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

**Write down the TARGET disk name** (e.g. `/dev/sda` or `/dev/sdb`) **only after matching model+size**. From now on I’ll call it **`/dev/TARGETDISK`** — replace with your actual disk (the whole disk, not `p1`/`1`).

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
**This erases `/dev/TARGETDISK` only.** Double-check it is `ProductCode` ~7.5G.

```sh
# unmount anything on the target (ignore errors if not mounted)
umount /dev/TARGETDISK* 2>/dev/null || true

# optional but clear
wipefs -a /dev/TARGETDISK

# interactive partitioner (recommended)
cfdisk /dev/TARGETDISK
```
In `cfdisk`:
1. Select **`gpt`** label type if asked.
2. Delete any existing partitions on **this disk only**.
3. New partition **#1**: size **`512M`**, type **`EFI System`** (ESP).
4. New partition **#2**: use **remaining space**, type **`Linux filesystem`**.
5. **`[ Write ]`** → type `yes` → **`[ Quit ]`**.

If `cfdisk` isn’t usable, `parted` alternative:
```sh
parted -s /dev/TARGETDISK mklabel gpt \
  mkpart ESP fat32 1MiB 513MiB set 1 esp on \
  mkpart LOBBY ext4 513MiB 100%
```

Verify:
```sh
lsblk -o NAME,MODEL,SIZE,TYPE,LABEL,FSTYPE /dev/TARGETDISK
```
Expect 2 partitions under the **7.5G ProductCode** disk.

## 6) Format partitions
**Replace `TARGETDISK1/2` with the real partition names** (may be `/dev/sda1/sda2` or `/dev/sdb1/sdb2`; NVMe would be `p1/p2` but you are **not** using NVMe).
```sh
mkfs.fat -F32 -n EFI /dev/TARGETDISK1
mkfs.ext4 -F -L qi-keydrive /dev/TARGETDISK2
```

## 7) Mount target filesystems
```sh
mount /dev/TARGETDISK2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/TARGETDISK1 /mnt/boot/efi
findmnt /mnt /mnt/boot/efi
```
Confirm `/mnt` is on the **7.5G/qi-keydrive** disk and `/mnt/boot/efi` is the EFI partition — **not nvme**.

## 8) Enable copy-on-write store (Guix installer)
```sh
herd start cow-store /mnt
```
(If `herd`/service differs or errors, note the message and continue only if you understand it; on the Guix installer this is normally needed.)

## 9) Create a minimal system configuration
```sh
mkdir -p /mnt/etc
cat > /mnt/etc/config.scm <<'EOF'
(use-modules (gnu) (gnu system nss))
(use-service-modules networking ssh)
(use-package-modules bootloaders certs screen ssh)

(operating-system
  (host-name "qimono-lobby")
  (timezone "Etc/UTC")
  (locale "en_US.utf8")

  ;; Portable UEFI removable bootloader for the lobby.
  (bootloader (bootloader-configuration
                (bootloader grub-efi-removable-bootloader)
                (targets '("/boot/efi"))))

  (file-systems (append
                  (list (file-system
                          (mount-point "/")
                          (device (file-system-label "qi-keydrive"))
                          (type "ext4"))
                        (file-system
                          (mount-point "/boot/efi")
                          (device (file-system-label "EFI"))
                          (type "vfat")))
                  %base-file-systems))

  (users (cons (user-account
                 (name "qi")
                 (group "users")
                 (supplementary-groups '("wheel" "netdev" "audio" "video")))
               %base-user-accounts))

  (packages (append (list screen openssh nss-certs) %base-packages))

  (services (append (list (service dhcp-client-service-type)
                          (service openssh-service-type))
                    %base-services)))
EOF
```
Notes: minimal lobby, `linux-libre`/defaults for the first boot (fine to start). `nss-certs` helps TLS. You can harden/customize later (and add `linux`+`linux-firmware` via a nonguix-aware setup when ready).

## 10) Initialize the system (this takes time)
```sh
guix system init /mnt/etc/config.scm /mnt
```
- Needs network for substitutes; may take a while.
- **If it fails with “No space left on device”:** the 7.5G target may be too small for this image/config. That’s a real capacity limit (not the TUI filter) — use a larger USB drive/SSD for Drive 2.
- **If it fails otherwise:** photo the last ~30 lines and the exact error.

## 11) Set passwords (before reboot)
```sh
# set root password
chroot /mnt /bin/sh -c 'passwd root'
# set user password
chroot /mnt /bin/sh -c 'passwd qi'
```
(If `chroot` path differs, try `/run/current-system/profile/bin/bash` or enter `guix shell ...` not needed; usually `passwd` works inside chroot on Guix.)

## 12) Reboot into the lobby
```sh
sync
umount -R /mnt
reboot
```
Remove the **SD installer** if convenient. Use the machine’s **UEFI boot menu** (`Esc`/boot menu; or BIOS priority) and pick the **`qi-keydrive` / ProductCode / USB thumbdrive (UEFI)** entry. **Do not boot the NVMe** unless you intend to return to Ubuntu.

## 13) After first boot (quick checks)
```sh
lsblk -o NAME,MODEL,SIZE,LABEL,MOUNTPOINT
ip -br a
guix --version
```

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
