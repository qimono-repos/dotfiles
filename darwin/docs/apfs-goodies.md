# APFS — the goodies worth using (and why it's "uncannily" like, yet unlike, ext4)

APFS (Apple File System) is the default on modern macOS since 10.13. It's the
reason relevant features like **clone files** exist and why the Mini's 256 GB
stretches further than an ext4 of the same size. Here's the toolkit.

## The one rule that bites: case-insensitive by default

APFS is case-**insensitive** by default: `~/Config` and `~/config` are the
**same** files. This is the #1 Linux-initiated surprise. You *can* format a
volume case-sensitive during erase, but don't — some apps assume
case-insensitivity. Just learn to not rely on case to separate things.

## The goodies (from those WWDC sessions — all real)

### 1. Clones — shallow, instant, space-free copies
`cp -c file clone` makes a **copy-on-write** clone: near-instant, and it shares
blocks until one side changes — zero extra disk for the duplicate. The kernel
reflinks them. Used automatically by many tools.

> Think of it as ext4 `reflink` (cp --reflink=auto) — but Apple made it the
> native default for `cp -c` instead of an opt-in flag.

```bash
cp -c bigfile backup    # instant, ~0 disk. Edit either: only changed blocks fork.
```

This is why apps like Time Machine snapshots, Xcode, and even 1 GiB+ files
clone instead of copy.

### 2. Snapshots — free, instant, point-in-time
`tmutil` / APFS snapshots give instant read-only snapshots. For a dev box the
brilliant use is: snapshot `~/source` or the container machine volume *before*
a risky change, roll back instantly if it breaks.

```bash
tmutil snapshot                                     # system snapshot (root volume)
diskutil apfs listSnapshots diskXY                # list
# Container/Guix: snapshot the VM disk before a `guix pull` you might regret.
```

### 3. Space sharing / container volumes
You don't partition. One **container** holds all volumes sharing a pool; free
space is fungible — a volume grows as you fill it, no resize headaches. So
don't "allocate space" to things; they just share. (Relevant: the container
machine disk simply lives in the pool.)

### 4. Fast encrypt / secure erase
`FileVault` = whole-disk encryption, free, and (because encryption is
per-block) fast and clone/snapshot-aware. Turn it on — near-zero cost on M4.

### 5. TRIM & SSD-aware, sparse files
APFS is designed for NVMe (which the Mini has). Sparse file support means huge
sparse images (like VM disks) use only their allocated blocks — again, why a
256 GB disk tolerates VMs better than you'd fear.

## Where Qimono will actually use these

- **Clone the dotfiles tree** before invasive edits: `cp -c -R ~/source ~/.qimono/backup-dotfiles-clone`.
- **Snapshot the container-machine VM disk** before risky `guix pull` / big
  `guix install` — instant rollback if the store breaks:
  `diskutil apfs listSnapshots` (machine disk), `tmutil snapshot`.
- **Sparse / shared pool** — don't worry about "space for the container"; it
  shares the pool. Just keep enough NET free (~30 GB) for `/gnu/store` + caches.
- **Case-insensitivity discipline** — never name two project files that differ
  only by case.

## Big-picture: ext4 vs APFS

| Property | ext4 | APFS |
|----------|------|------|
| Snapshots | LVM/reflink needed | **native (tmutil)** |
| Clones/reflink | `cp --reflink=auto`, manual | **default clone via `cp -c`** |
| Case | sensitive (usually) | **insensitive (default)** |
| Space mgmt | partitions (fixed) | **container, shared pool, auto-grow** |
| Encryption | fscrypt/LUKS | **FileVault, per-block** |
| Checksums | no | yes (but perf-off by default) |
| Designed for | spinning/NVMe | **NVMe-first** |

## Practical bottom line for the Mini (256 GB)

The good news of APFS's sharing/cloning is that 11 GB free is more forgiving
than ext4 would make it, but net-freespace is still the metric that counts —
`/gnu/store`, the container VM disk, and caches all live in the pool. Run
`disk-audit.sh` to find the real reclaim (mostly `~/Library` caches + old
simulator runtimes — which ARE re-addable on demand).