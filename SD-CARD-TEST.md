# SD Card Troubleshooting Record — `SD-CARD-TEST.md`

- **Date:** 2026-08-06
- **Machine:** Lenovo Yoga (hostname `qimono-localhost`, Ubuntu)
- **Card reader:** internal PCI SDHCI (`mmc0: SDHCI controller on PCI [0000:03:00.0] using ADMA`)
- **Device:** `/dev/mmcblk0` (whole disk), `/dev/mmcblk0p1` (partition)
- **Card name (as reported):** `asdfg`, 58.6 GiB, SDXC

---

## 1. Verdict (TL;DR)

- The card is **counterfeit / over-sized**. It **advertises 58.6 GiB** but its **real, persistent flash is below ~30 GiB**.
- This single fact is the root cause of every mount failure:
  - `mkfs.ext4` puts the journal in the **tail of the filesystem (~58.4 GiB)** — in the card's **phantom (non-persistent) region**.
  - The journal never survives on the card, so every mount fails with
    `JBD2: no valid journal superblock found` → `EXT4-fs: Could not load journal inode`,
    even after `e2fsck` regenerated the journal.
- **Real card size — verdict:** between **~1 GiB and 30 GiB**, most likely a **32 GB flash (~29.8 GiB)** re-flashed to report 64 GB.
  Exact value **pending** `f3probe` (placeholder in §7).

---

## 2. Symptoms

1. `parted mklabel gpt` + `mkpart` succeed, but parted warns **"The backup GPT table is corrupt"**.
2. `mkfs.ext4 -L QIMONO-NOMAD` **succeeds** and reports a UUID.
3. `blkid` immediately after shows a valid ext4 filesystem.
4. `mount` fails with:
   ```
   mount: /mnt/qimono-nomad: wrong fs type, bad option, bad superblock on /dev/mmcblk0p1, ...
   ```
   Kernel log:
   ```
   JBD2: no valid journal superblock found
   EXT4-fs (mmcblk0p1): Could not load journal inode
   ```
5. `e2fsck -f` repairs the journal, but the very next `mount` **fails with the identical error**.
6. The **same process failed on a second SD card** (first card also failed with this process; a different card wrote a Linux ISO via balenaEtcher successfully).

---

## 3. Hardware facts

- **Device nodes:** `mmcblk0` (major 179), `mmcblk0p1`
- **Advertised geometry:** total `122880000` sectors (= exactly 60000 MiB = 58.6 GiB); partition starts at sector `2048` (1 MiB), size `122875904` sectors
- **CID:** `05000c6173646667220000001201a300`
  - the OEM field decodes to ASCII **`asdfg`** (61 73 64 66 67) — a generic/counterfeit placeholder
- **manfid:** `0x05` · **serial:** `0x12` · **date:** `03/2026`
- **Kernel enumeration:** `mmc0:0001 asdfg 58.6 GiB`
- **Original card contents:** a single vfat partition, auto-mounted by the desktop at `/run/media/qi/disk`

---

## 4. Full command log

### 4.1 Initial state

```console
$ lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,UUID
mmcblk0      58.6G disk
└─mmcblk0p1  58.6G part vfat
nvme0n1     476.9G disk                                              Micron MTFDKCD512TGE-1BK1AABLA
├─nvme0n1p5 156.3G part ext4     /                                  1962fc83-161b-45ba-bce2-5a62425d90bb
```

### 4.2 Partition + format (per SD-CARD-README.md Part 1)

```console
$ export SD_DEV=/dev/mmcblk0
$ export SD_PART=/dev/mmcblk0p1

$ sudo parted /dev/mmcblk0 mklabel gpt
Warning: The existing disk label on /dev/mmcblk0 will be destroyed and all data on this disk will be lost. Do you want to continue?
Yes/No? y
Information: You may need to update /etc/fstab.

$ sudo parted /dev/mmcblk0 mkpart primary ext4 1MiB 100%
Error: The backup GPT table is corrupt, but the primary appears OK, so that will be used.
OK/Cancel? ok
Partition name?  []? QI-SDCARD
File system type?  [ext2]? ext4
Start? 1
End? 100%
Information: You may need to update /etc/fstab.

$ sudo mkfs.ext4 -L QIMONO-NOMAD /dev/mmcblk0p1
mke2fs 1.47.2 (1-Jan-2025)
Discarding device blocks: done
Creating filesystem with 15359488 4k blocks and 3842048 inodes
Filesystem UUID: 46f95af3-5b24-45ab-9e97-1b17aa5cadd6
Superblock backups stored on blocks: 32768, 98304, ...
Creating journal (65536 blocks): done
Writing superblocks and filesystem accounting information: done

$ sudo blkid /dev/mmcblk0p1
/dev/mmcblk0p1: LABEL="QIMONO-NOMAD" UUID="46f95af3-5b24-45ab-9e97-1b17aa5cadd6" BLOCK_SIZE="4096" TYPE="ext4" PARTLABEL="QI-SDCARD" PARTUUID="a57917d9-54ae-4e18-9676-93c3bebf6e1e"
```

### 4.3 First mount attempt — fails

```console
$ sudo mount /dev/mmcblk0p1 /mnt/qimono-nomad
mount: /mnt/qimono-nomad: wrong fs type, bad option, bad superblock on /dev/mmcblk0p1, missing codepage or helper program, or other error.
       dmesg(1) may have more information after failed mount system call.
```

Kernel log (authoritative):

```
Aug 06 05:39:23 qimono-localhost kernel: JBD2: no valid journal superblock found
Aug 06 05:39:23 qimono-localhost kernel: EXT4-fs (mmcblk0p1): Could not load journal inode
```

### 4.4 `e2fsck` — repairs, but mount still fails

```console
$ sudo e2fsck -f /dev/mmcblk0p1
e2fsck 1.47.2 (1-Jan-2025)
Superblock has an invalid journal (inode 8).
Clear<y>? yes
*** journal has been deleted ***
Superblock has_journal flag is clear, but a journal is present.
Clear<y>? yes
Pass 1: Checking inodes, blocks, and sizes
Journal inode is not in use, but contains data.  Clear<y>? yes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 4: Checking reference counts
Pass 5: Checking group summary information
Block bitmap differences:  +1048576 +1048592 +(1048610--1048612) ... -15359356 -15359358 -(15359360--15359361) ...
Fix<y>? yes
Free blocks count wrong for group #225 (0, counted=32768).      Fix<y>? yes
Free blocks count wrong for group #226 (0, counted=32768).      Fix<y>? yes
Free blocks count wrong (15038939, counted=15104475).            Fix<y>? yes
Recreate journal<y>? yes
Creating journal (65536 blocks):  Done.
*** journal has been regenerated ***
QIMONO-NOMAD: ***** FILE SYSTEM WAS MODIFIED *****
QIMONO-NOMAD: 12/3842048 files (0.0% non-contiguous), 320549/15359488 blocks
```

Then, minutes later:

```console
$ sudo mount /dev/mmcblk0p1 /mnt/qimono-nomad
mount: ... wrong fs type, bad option, bad superblock ...
```

Kernel log again:

```
Aug 06 05:56:07 qimono-localhost kernel: JBD2: no valid journal superblock found
Aug 06 05:56:07 qimono-localhost kernel: EXT4-fs (mmcblk0p1): Could not load journal inode
Aug 06 07:42:28 qimono-localhost kernel: JBD2: no valid journal superblock found   (mount attempt #3)
Aug 06 07:42:49 qimono-localhost kernel: JBD2: no valid journal superblock found   (mount attempt #4)
```

The error is **identical and stable** across all four mount attempts, including after a full journal regeneration.

### 4.5 Persistence spot-test (decisive)

```console
# INVALID first attempt — wrote past the end of the card (see §5 note)
$ sudo dd if=/dev/urandom of=/tmp/pat bs=1M count=1
$ sudo dd if=/tmp/pat of=/dev/mmcblk0 bs=1M seek=60000 count=1
dd: IO error: No space left on device

# VALID spot test — offsets inside the advertised 60000 MiB card
$ for M in 1000 30720 45000 59800; do
    sudo dd if=/dev/urandom of=/tmp/pat bs=1M count=1 status=none
    sudo dd if=/tmp/pat of=/dev/mmcblk0 bs=1M seek=$M count=1 status=none
    sync && sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    if sudo dd if=/dev/mmcblk0 bs=1M skip=$M count=1 status=none 2>/dev/null | cmp -s - /tmp/pat; then
      echo "offset ${M} MiB: PERSISTS"
    else
      echo "offset ${M} MiB: LOST or refused"
    fi
  done
offset 1000 MiB: PERSISTS
offset 30720 MiB: LOST or refused
offset 45000 MiB: LOST or refused
offset 59800 MiB: LOST or refused
```

---

## 5. Diagnostics & results

### 5.1 Write-persistence table

| Offset (MiB) | Approx. location | Result |
|--------------|------------------|--------|
| 1000 (1 GiB) | near front       | **PERSISTS** |
| 30720 (30 GiB) | mid-card        | **LOST / refused** |
| 45000 (44 GiB) | high region      | **LOST / refused** |
| 59800 (58.4 GiB) | tail (journal region) | **LOST / refused** |

> **Note on the invalid first test:** `seek=60000` with `bs=1M` targets byte offset 60000 MiB, which is **exactly past the end** of the card (the card is exactly 60000 MiB = `122880000 × 512` bytes). `dd: IO error: No space left on device` is the correct kernel response for any healthy card there, so that line is **not evidence**. The corrected loop above is the valid test.

### 5.2 What the data proves

- Writes **persist** at the front of the card (1 GiB).
- Writes **do not persist** (are refused or silently lost) from **30 GiB onward**.
- Therefore the card's **real capacity is < 30 GiB**, while it advertises 58.6 GiB.

### 5.3 Kernel/journal evidence

- `JBD2: no valid journal superblock found` on every mount — the journal region is unreadable/invalid **every time**.
- e2fsck corruption was confined to:
  - block ~1048576 (**4 GiB** mark),
  - block groups #225–226 (**~28 GiB** mark — the suspected real-capacity boundary),
  - blocks 15359356–15359487 (the **very end** of the filesystem).

### 5.4 GNOME / udisks auto-mount: ruled out

The only udisks event involving the card was:

```
Aug 06 05:14:09 qimono-localhost udisksd[1635]: Cleaning up mount point /run/media/qi/disk (device 179:1 is not mounted)
```

That unmounted the **original vfat** and happened **before** partitioning. There were **no udisks/gvfs/GNOME events** during `mkfs`, `e2fsck`, or any of the four mount attempts. Auto-mounting is read-oriented and cannot corrupt a just-written journal. The failure is purely the kernel failing to read the journal region from the card.

---

## 6. Root-cause analysis

| Observation | Explanation |
|-------------|-------------|
| `mkfs.ext4` succeeds, `blkid` sees ext4 | The main superblock (front of card) persists and is read correctly. Reads right after mkfs were also served from the page cache before writeback. |
| Mount always fails on the journal | A fresh mkfs on a 58.6 GiB fs places the 65536-block journal at the **tail (~58.4 GiB)** — in the card's phantom region. Those writes never survive. |
| `e2fsck` regenerates the journal, mount still fails | The regenerated journal is written to the same phantom tail. Nothing can persist there. |
| parted: "backup GPT table is corrupt" | The backup GPT lives at the last sector (~58.6 GiB) — phantom space. |
| e2fsck corruption at ~28 GiB | That is the boundary of the card's real flash (suspected ~29.8 GiB = 32 GB flash). |
| balenaEtcher "verified" an ISO on the other card | The ISO is only a few GB and fits inside the real flash. Verifying it does **not** prove the advertised 58.6 GiB — fake cards pass for small images. |
| Two cards failed with the same process | Both are almost certainly from the same counterfeit batch. |

---

## 7. Real SD card size — verdict

- **Confirmed bound:** real persistent capacity is **≥ 1 GiB and < 30 GiB**.
- **Most likely value:** **~29.8 GiB (a 32 GB flash)** re-flashed to report 64 GB / 58.6 GiB.
- **Definitive measurement — PENDING (placeholder):**

```console
$ sudo apt install -y f3
$ sudo f3probe /dev/mmcblk0
# --- PLACEHOLDER: fill in f3probe output here ---
# Example expected output on a 64GB-fake/32GB-real card:
#   Device size: 58.6 GiB, and contains a valid MBR
#   LBA 0..200 is reserved
#   ... more than 50% suspicious ...
#   Real size: 29.8 GiB
# --- END PLACEHOLDER ---
```

---

## 8. Next steps

1. **Run `f3probe`** (above) to confirm the exact real size. Optionally `f3fix` can re-partition the card to its true size.
2. **Replace (recommended):** buy a genuine branded 64 GB card (SanDisk / Samsung / KIOXIA) from a real retailer, and `f3probe` it *before* trusting it.
3. **Salvage (free, interim):** re-partition this card to a size safely under its real capacity (e.g., ~26–27 GiB), then `mkfs.ext4`, `sync`, `partprobe`, and verify with `e2fsck -f` + `mount` **immediately**. Keep everything under the boundary; treat the card as disposable (dotfiles live on git anyway). Do **not** put the quantum workspace / Python venvs on it.
4. **Safeguards to fold into `SD-CARD-README.md` workflow (any route):**
   - `sudo partprobe` after `parted` (or after any partition-table change)
   - `sync` after `mkfs` before unmounting/removing the card
   - verify with `sudo e2fsck -f` + `sudo mount` before continuing
   - use `sudo blkid /dev/mmcblk0p1` (real read) rather than trusting cached `lsblk` FSTYPE/UUID output
   - run `f3probe` on any new card before relying on it
