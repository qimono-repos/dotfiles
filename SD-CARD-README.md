# SD card portable home — human tutorial (P5)

**No SD card is required to read this.**  
As of authoring, the Lenovo Yoga **did not** have a physical SD inserted. This is the playbook for when you do.

Goal: a portable user tree (recommended: **`qimono-nomad`**, not your daily `qi` home) that can move between machines after you re-run discovery, Guix/uv rebuilds, and stow.

Related: `ubuntu-len-yog-AMD64/docs/teach-portable-home.md` · `scripts/machine-discovery.sh`

---

## Safety rules

1. **Do not** move live `/home/qi` to SD until nomad works.  
2. Use a **fixed UID** for `qimono-nomad` (e.g. **2000**) on every machine.  
3. Filesystems travel; **binaries do not** across x86_64 ↔ aarch64.  
4. Encrypt (LUKS) if the card holds secrets.  
5. Dual-boot Yoga: unmount cleanly before Windows or yanking the card.

---

## Part 0 — What you need

- SD card (or USB stick) large enough for source + profiles (32 GB+ recommended).  
- Backup of anything important.  
- This `dotfiles` git clone (or a tarball of it on the card).  
- Network on the target machine for Guix substitutes / uv.

---

## Part 1 — On the machine that formats the card

### 1. Insert and identify the device

```bash
# Watch kernel messages when you insert
sudo dmesg -w
# or list block devices
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,UUID
```

Find the SD (often `mmcblk0` or `sdX`). **Partition carefully** — wrong disk destroys data.

```bash
# Example only — REPLACE with your device
export SD_DEV=/dev/mmcblk0      # whole disk
export SD_PART=/dev/mmcblk0p1  # partition you will use
```

### 2. Partition + format (ext4, simple)

```bash
# Destructive example — confirm SD_DEV three times mentally
sudo parted -s "$SD_DEV" mklabel gpt
sudo parted -s "$SD_DEV" mkpart primary ext4 1MiB 100%
sudo mkfs.ext4 -L QIMONO-NOMAD "$SD_PART"
sudo blkid "$SD_PART"   # note UUID=
```

### 3. Mount and create skeleton

```bash
sudo mkdir -p /mnt/qimono-nomad
sudo mount "$SD_PART" /mnt/qimono-nomad
sudo chown "$USER:$USER" /mnt/qimono-nomad

mkdir -p /mnt/qimono-nomad/{source/repos,tmp,.config,.local}
# clone or rsync dotfiles onto the card
git clone <YOUR_DOTFILES_URL> /mnt/qimono-nomad/source/repos/qimono-repos/dotfiles
# or: rsync -a ~/source/repos/qimono-repos/dotfiles/ /mnt/qimono-nomad/source/repos/qimono-repos/dotfiles/
```

### 4. Unmount before eject

```bash
sync
sudo umount /mnt/qimono-nomad
```

---

## Part 2 — On the machine that will *use* the card

### 1. Discover the host (always)

```bash
cd /path/to/dotfiles/ubuntu-len-yog-AMD64
./scripts/machine-discovery.sh | tee /tmp/machine-discovery-$(hostname).txt
```

Read arch (`x86_64` vs `aarch64`), RAM, existing Guix, and free disk **before** big installs.

### 2. Create nomad user (once per machine)

```bash
sudo adduser --uid 2000 --home /home/qimono-nomad --disabled-password qimono-nomad
sudo usermod -aG sudo qimono-nomad   # optional
```

### 3. Mount SD at the home path

```bash
lsblk -f
export SD_PART=/dev/disk/by-uuid/PASTE-UUID-HERE
# temporary mount
sudo mount "$SD_PART" /home/qimono-nomad
sudo chown 2000:2000 /home/qimono-nomad

# permanent (after testing): add to /etc/fstab
# UUID=....  /home/qimono-nomad  ext4  defaults,nofail  0  2
```

`nofail` lets the machine boot if the card is absent.

### 4. Login as nomad

```bash
sudo -iu qimono-nomad
# or graphical login
```

### 5. Guix + stow + bootstrap

If Guix is missing on that host, install it first (see `qimono-repos/install-guix-ready.sh`).

```bash
# as qimono-nomad
export GUIX_PROFILE="$HOME/.guix-profile"
# after guix install stow python uv (or manifests):
source "$GUIX_PROFILE/etc/profile" 2>/dev/null || true

cd "$HOME/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64"
# Machine pack name may differ on Snapdragon — use the pack that matches arch
./scripts/install-guix-python-uv.sh
./scripts/stow-apply.sh
# full quantum stack only if RAM/disk allow:
# ./scripts/bootstrap.sh
```

Stow command equivalent:

```bash
stow -d stow-source -t "$HOME" -v shell guix-env quantum
```

### 6. Rebuild arch-specific bits

```bash
guix package -m guix/manifests/base.scm
# uv projects: never copy .venv from another CPU arch
cd ~/source/repos/qimono-repos/quantum-workspace 2>/dev/null || true
uv sync   # or re-run install-quantum-python.sh
```

### 7. Clean unmount

```bash
exit   # leave nomad shell
sudo umount /home/qimono-nomad
```

---

## Part 3 — Moving between machines

| From → To | Action |
|-----------|--------|
| Yoga AMD64 → Intel x86_64 laptop | Mount, stow, maybe `guix package -u`; often OK |
| Yoga → Snapdragon / Pi (aarch64) | Mount sources OK; **rebuild** Guix profile + uv venv |
| Linux → Mac mini | Do not expect raw ext4 home; use git/rsync into macOS home or Linux VM |

Always run **`machine-discovery.sh`** on the new chassis first.

---

## Part 4 — Troubleshooting

| Symptom | Check |
|---------|--------|
| Permission denied in home | UID must match (2000); `chown -R 2000:2000` |
| Guix commands missing | `source ~/.guix-profile/etc/profile`; guix-daemon running |
| Stow conflicts | Diff and backup real files; see `docs/stow.md` |
| Card not visible | Adapter, `dmesg`, disable “USB storage” blocks |
| Boot hangs on missing SD | Add `nofail` in fstab |

---

## Checklist (print-friendly)

- [ ] Card formatted `QIMONO-NOMAD` ext4, UUID recorded  
- [ ] Dotfiles present under `…/source/repos/qimono-repos/dotfiles`  
- [ ] User `qimono-nomad` uid 2000 on target  
- [ ] `machine-discovery.sh` saved for that host  
- [ ] Guix profile rebuilt on that arch  
- [ ] `stow-apply.sh` OK  
- [ ] Clean `umount` before removal  
