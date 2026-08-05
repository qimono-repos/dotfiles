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
# Watch kernel messages in real-time as you physically insert the SD card
# This shows you exactly which device name Linux assigns (/dev/sdX or /dev/mmcblk0)
# Press Ctrl+C to stop after insertion
sudo dmesg -w

# Alternative: list all block devices in a table with useful columns
# NAME = device name (e.g., sda1, mmcblk0p1) | SIZE = capacity
# FSTYPE = filesystem type | MODEL = device description | UUID = unique identifier
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL,UUID
```

Find the SD (often `mmcblk0` or `sdX`). **Partition carefully** — wrong disk destroys data.

```bash
# Set environment variables (temporary, stored in memory for this terminal session only)
# SD_DEV = the entire disk device (e.g., /dev/mmcblk0 or /dev/sda, no partition number)
# SD_PART = a specific partition on that disk (e.g., /dev/mmcblk0p1 = partition 1 on mmcblk0)
# REPLACE mmcblk0 with your actual device name (sda, sdb, etc.) from the lsblk output above
export SD_DEV=/dev/mmcblk0      # whole disk device
export SD_PART=/dev/mmcblk0p1   # partition 1 of that device
```

### 2. Partition + format (ext4, simple)

```bash
# WARNING: This will erase everything on the SD card. Triple-check SD_DEV is correct!
# sudo = run as administrator (root); parted = partitioning tool; -s = silent mode (no prompts)
# mklabel gpt = create a new partition table in GPT format (modern, supports large disks)
sudo parted -s "$SD_DEV" mklabel gpt

# mkpart = create a new partition | primary = main type | ext4 = filesystem
# 1MiB 100% = start at 1 megabyte, end at the disk's full size (leaves space for boot sector)
sudo parted -s "$SD_DEV" mkpart primary ext4 1MiB 100%

# IMPORTANT: only format the partition device, never the whole disk device.
# Use the partition path ($SD_PART) such as /dev/mmcblk0p1.
# Running mkfs.ext4 without the partition path can overwrite the wrong device.
# mkfs.ext4 = format the partition with ext4 filesystem (reliable, Linux standard)
# -L QIMONO-NOMAD = give this partition a human-readable label you'll see in file managers
sudo mkfs.ext4 -L QIMONO-NOMAD "$SD_PART"

# blkid = show block device information | grep and note the UUID= value for later use
# You'll need this UUID to mount the SD card permanently in /etc/fstab
sudo blkid "$SD_PART"
```

### 3. Mount and create skeleton

```bash
# mkdir -p = create directory (including parent directories); -p = skip error if already exists
# /mnt/ = standard Unix location for mounting removable devices (USB, SD cards, etc.)
# This creates an empty folder where we will attach the SD card filesystem
sudo mkdir -p /mnt/qimono-nomad

# mount = attach the SD card filesystem so we can read/write files
# $SD_PART = the device we formatted earlier (e.g., /dev/mmcblk0p1)
# /mnt/qimono-nomad = the local folder where the SD contents become visible
sudo mount "$SD_PART" /mnt/qimono-nomad

# Verify the mount succeeded before continuing
# mount | grep /mnt/qimono-nomad should show the device mounted as ext4
# If this fails, run: dmesg | tail -20 and check the partition/format commands above
mount | grep /mnt/qimono-nomad

# chown = change owner; "$USER" = your current login name
# By default, sudo creates files owned by root; this makes YOU the owner so you can write files
sudo chown "$USER:$USER" /mnt/qimono-nomad

# Create nested folder structure in one command using {comma,separated,paths}
# source/repos = where your code/repositories live
# tmp = temporary files | .config = config files (hidden folders start with .)
# .local = local user data (hidden)
mkdir -p /mnt/qimono-nomad/{source/repos,tmp,.config,.local}

# git clone = download the dotfiles repository from a remote server onto the SD card
# <YOUR_DOTFILES_URL> = REPLACE with your actual git repository URL
git clone <YOUR_DOTFILES_URL> /mnt/qimono-nomad/source/repos/qimono-repos/dotfiles

# Alternative: rsync = copy files more efficiently if dotfiles already exist locally
# -a = archive (preserves permissions and timestamps) | trailing / = copy contents, not folder itself
# rsync -a ~/source/repos/qimono-repos/dotfiles/ /mnt/qimono-nomad/source/repos/qimono-repos/dotfiles/
```

### 4. Unmount before eject

```bash
# sync = flush all pending writes from memory to the physical SD card
# Without this, the system may still be writing when you eject; data loss can occur
# Press Enter and wait for the prompt to return before proceeding
sync

# umount = safely disconnect the filesystem (opposite of mount)
# /mnt/qimono-nomad = the mount point we used earlier
# After this command, it is safe to physically remove the SD card
sudo umount /mnt/qimono-nomad
```

---

## Part 2 — On the machine that will *use* the card

### 1. Discover the host (always)

```bash
# cd = change directory | /path/to/dotfiles = REPLACE with your actual dotfiles path
# This moves your terminal into the dotfiles folder
cd /path/to/dotfiles/ubuntu-len-yog-AMD64

# ./ = run the script in the current directory (not from PATH)
# machine-discovery.sh = script that profiles your system (CPU, RAM, disk, OS version)
# | tee = pipe (send output) to tee command, which writes BOTH to screen and to a file
# /tmp/machine-discovery-$(hostname).txt = saves results with your machine's name
./scripts/machine-discovery.sh | tee /tmp/machine-discovery-$(hostname).txt
```

Read arch (`x86_64` vs `aarch64`), RAM, existing Guix, and free disk **before** big installs.

### 2. Create nomad user (once per machine)

```bash
# adduser = create a new user account on this machine
# --uid 2000 = assign user ID 2000 (same on every machine for SD card portability)
# --home /home/qimono-nomad = this user's home directory (where SD card will mount)
# --disabled-password = no password needed to login as this user (secure for SSH keys)
# qimono-nomad = the username (cannot contain uppercase letters or spaces)
sudo adduser --uid 2000 --home /home/qimono-nomad --disabled-password qimono-nomad

# usermod = modify user account | -aG = add to groups (append, not replace)
# sudo = allow this user to run administrator commands (requires no password with NOPASSWD)
# Optional: only if you want the nomad user to have admin privileges
sudo usermod -aG sudo qimono-nomad
```

### 2.5 Smart .zshrc environment variable setup (stow-compatible)

This step automatically detects your SD card device and creates/appends to `.zshrc` with environment variables. It's **non-destructive** (uses `>>` append instead of overwriting).

**First, ensure zsh is installed:**

```bash
# Check if zsh is installed; apt-get shows which package manager is in use
which zsh

# If not found, install zsh (Ubuntu/Debian):
sudo apt-get update && sudo apt-get install -y zsh

# Fedora users:
# sudo dnf install -y zsh
```

**Then run this smart setup script:**

```bash
#!/usr/bin/env bash
# This script intelligently sets up .zshrc with SD card environment variables
# It works on any machine and doesn't overwrite existing .zshrc content

# Precondition: ensure zsh is installed
if ! command -v zsh &> /dev/null; then
  echo "ERROR: zsh is not installed. Run: sudo apt-get install -y zsh"
  exit 1
fi

# Define the path to the .zshrc file
ZSHRC_PATH="$HOME/.zshrc"

# Step 1: Create .zshrc if it doesn't exist (blank file)
if [ ! -f "$ZSHRC_PATH" ]; then
  echo "# Default .zshrc created by dotfiles setup" > "$ZSHRC_PATH"
  echo "# This file is synced with stow, do not edit directly" >> "$ZSHRC_PATH"
  echo "" >> "$ZSHRC_PATH"
  echo ".zshrc created at $ZSHRC_PATH"
fi

# Step 2: Check if SD card environment variables are already present (avoid duplicates)
if grep -q "# SD Card Environment Variables" "$ZSHRC_PATH"; then
  echo ".zshrc already contains SD Card variables. Skipping append."
  exit 0
fi

# Step 3: Auto-detect SD card device and UUID
# This handles both mmcblk0 (newer boards) and sdX (older adapters)
echo "Detecting SD card device..."

# Find the SD card by looking for common patterns and getting its UUID
SD_DEVICES=$(lsblk -d -p -n -o NAME,MODEL,SIZE | grep -iE "sd|mmc" | awk '{print $1}')

if [ -z "$SD_DEVICES" ]; then
  echo "WARNING: No SD card device detected. You can add variables manually later."
  echo "Re-run this script after inserting the SD card."
  exit 1
fi

# Show devices and ask user to pick (if multiple found)
echo "Found potential SD devices:"
echo "$SD_DEVICES"
echo ""

# Get the first one found (or manually set if needed)
SD_DEV=$(echo "$SD_DEVICES" | head -n1)
echo "Using: $SD_DEV"

# Get UUID of the partition (assuming partition 1)
SD_UUID=$(sudo blkid -s UUID -o value "${SD_DEV}1" 2>/dev/null)

if [ -z "$SD_UUID" ]; then
  echo "WARNING: Could not determine SD card UUID. You may need to set it manually."
  SD_UUID="YOUR-SD-UUID-HERE"
fi

# Step 4: Append environment variables to .zshrc (non-destructive >>)
cat >> "$ZSHRC_PATH" << 'EOF'

# ============================================================================
# SD Card Environment Variables (auto-configured for portability)
# ============================================================================
# These variables make your setup work on different machines
# .zshrc is synced via stow, so changes here propagate across machines

# SD_DEV = the physical SD card device name (varies by machine)
# Detect on the fly: mmcblk0 on RPi/newer boards, sdX on older USB adapters
if [ -b /dev/mmcblk0p1 ]; then
  export SD_DEV=/dev/mmcblk0
  export SD_PART=/dev/mmcblk0p1
elif [ -b /dev/sda1 ]; then
  export SD_DEV=/dev/sda
  export SD_PART=/dev/sda1
elif [ -b /dev/sdb1 ]; then
  export SD_DEV=/dev/sdb
  export SD_PART=/dev/sdb1
else
  # Fallback: manually set by user
  export SD_DEV="/dev/mmcblk0"
  export SD_PART="/dev/mmcblk0p1"
fi

# SD_UUID = unique identifier for your SD card (stable, works even if device name changes)
# This is the recommended way to reference the SD card in /etc/fstab
export SD_UUID="PASTE-YOUR-UUID-HERE"

# SD_MOUNT_POINT = where the SD card home directory is mounted
# e.g., /home/qimono-nomad or /mnt/sd-portable
export SD_MOUNT_POINT="/home/qimono-nomad"

# Convenience: add SD mount path to CDPATH so you can cd to it quickly
# After sourcing this .zshrc, you can type: cd qimono-nomad (without full path)
export CDPATH="$CDPATH:$SD_MOUNT_POINT"

# Helper alias to check SD card mount status
alias sd-status='echo "SD Device: $SD_DEV | Partition: $SD_PART | UUID: $SD_UUID | Mount: $SD_MOUNT_POINT" && lsblk | grep -E "mmcblk0|sda|sdb" || echo "No SD card found"'

# Helper alias to mount SD card (if not auto-mounted)
# Usage: sd-mount (but this requires sudo, so you may need to call sudo sd-mount)
alias sd-mount='sudo mkdir -p "$SD_MOUNT_POINT" && sudo mount /dev/disk/by-uuid/"$SD_UUID" "$SD_MOUNT_POINT" && echo "SD card mounted at $SD_MOUNT_POINT"'

# Helper alias to unmount SD card safely
alias sd-umount='sync && sudo umount "$SD_MOUNT_POINT" && echo "SD card safely unmounted"'

# ============================================================================
EOF

echo ""
echo "✓ SD Card environment variables appended to $ZSHRC_PATH"
echo ""
echo "Next steps:"
echo "1. Edit $ZSHRC_PATH and replace PASTE-YOUR-UUID-HERE with your actual UUID"
echo "   Run: lsblk -o NAME,UUID to find your SD card's UUID"
echo ""
echo "2. Reload .zshrc:"
echo "   source ~/.zshrc"
echo ""
echo "3. Test the variables:"
echo "   echo \$SD_DEV \$SD_PART \$SD_MOUNT_POINT"
echo ""
echo "4. Try the helpers:"
echo "   sd-status    # show SD card info"
echo "   sd-mount     # mount the SD card (requires sudo)"
echo "   sd-umount    # unmount safely"
```

**Save the script above as `setup-sd-zshrc.sh` and run it:**

```bash
# Make it executable (allows you to run it as a command)
chmod +x setup-sd-zshrc.sh

# Run the script (it will auto-detect your SD card and update .zshrc)
./setup-sd-zshrc.sh

# Reload your shell to apply new environment variables
exec zsh
```

**Why this approach is smart:**

- **Non-destructive:** Uses `>>` (append) not `>` (overwrite)
- **Auto-detects:** Finds `/dev/mmcblk0` or `/dev/sdX` automatically on any machine
- **Portable:** Uses UUID instead of device name (survives USB adapter changes)
- **Stow-compatible:** .zshrc is synced via stow to all machines; device detection runs on each machine
- **Idempotent:** Won't add duplicate lines if run multiple times (checks for `# SD Card Environment Variables` marker)
- **Helpful aliases:** Includes `sd-status`, `sd-mount`, `sd-umount` for quick management

**After stow links .zshrc:**

If you've already run stow and `.zshrc` is a symlink to `stow-source/shell/zshrc`, the appended variables in `stow-source/shell/zshrc` will be visible on all machines. Just update the UUID on each machine as needed.

### 3. Mount SD at the home path

```bash
# lsblk -f = list all block devices with UUID (unique identifier) for each partition
# Find your SD card UUID in the output (UUID=xxxx-xxxx-xxxx format)
lsblk -f

# export = store this variable for use in the rest of this terminal session
# /dev/disk/by-uuid/ = safe path that finds disks by UUID (works even if device name changes)
# PASTE-UUID-HERE = REPLACE with the actual UUID from lsblk output (e.g., a1b2c3d4-e5f6-1234-abcd-ef1234567890)
export SD_PART=/dev/disk/by-uuid/PASTE-UUID-HERE

# sudo mount = attach the SD card; /home/qimono-nomad = destination (where files appear)
# Temporary mount: SD card is connected only while the machine is running
sudo mount "$SD_PART" /home/qimono-nomad

# chown 2000:2000 = change ownership to user ID 2000, group ID 2000 (the nomad account)
# This ensures the nomad user can read and write in their home directory
sudo chown 2000:2000 /home/qimono-nomad

# PERMANENT MOUNT (after testing): edit /etc/fstab with sudo nano or sudo vim
# This makes the SD card auto-mount on every boot
# Add this line to /etc/fstab:
# UUID=a1b2c3d4-e5f6-1234-abcd-ef1234567890  /home/qimono-nomad  ext4  defaults,nofail  0  2
# nofail = boot succeeds even if SD card is missing; defaults = use standard mount options
```

`nofail` lets the machine boot if the card is absent.

### 4. Login as nomad

```bash
# sudo -iu qimono-nomad = switch to the qimono-nomad user account with their environment
# -i = login shell (loads .zshrc and environment variables)
# -u = which user to switch to
# After this, your prompt shows you are now the nomad user
sudo -iu qimono-nomad

# Graphical login: select "qimono-nomad" at the login screen (e.g., GNOME, KDE login)
# or use: startx -- :1 (if available)
```

### 5. Guix + stow + bootstrap

If Guix is missing on that host, install it first (see `qimono-repos/install-guix-ready.sh`).

```bash
# You are now logged in as qimono-nomad user
# GUIX_PROFILE = path to where Guix installed packages (e.g., ~/.guix-profile/bin)
# $HOME = shorthand for the current user's home directory (/home/qimono-nomad)
export GUIX_PROFILE="$HOME/.guix-profile"

# source = load environment variables from a script file
# This adds Guix binaries to your PATH so you can run them
# 2>/dev/null = suppress errors if the file doesn't exist
# || true = if source fails, continue anyway (do not stop)
source "$GUIX_PROFILE/etc/profile" 2>/dev/null || true

# cd = change directory to the dotfiles on the SD card
# $HOME = your nomad user's home (on the mounted SD card)
cd "$HOME/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64"

# Run setup scripts (may take 10-30 minutes on first run)
# Machine pack name may differ on Snapdragon — use the pack that matches your CPU arch
./scripts/install-guix-python-uv.sh

# stow-apply.sh = creates symlinks from dotfiles to your home directory
# This lets you version-control your config files in git
./scripts/stow-apply.sh

# Full quantum stack only if you have enough RAM and disk space
# Quantum tools are large (several GB); skip if space is tight
# ./scripts/bootstrap.sh
```

Stow command equivalent (manual stow linking):

```bash
# stow = create symlinks from dotfiles to target directory
# -d stow-source = look for dotfiles in the stow-source folder
# -t $HOME = target directory where symlinks are created (your home)
# -v = verbose (show each symlink created)
# shell guix-env quantum = which package directories to link
stow -d stow-source -t "$HOME" -v shell guix-env quantum
```

### 6. Rebuild arch-specific bits

```bash
# guix package -m = install packages listed in a manifest file
# guix/manifests/base.scm = the manifest (list of packages to install)
# This ensures all tools are rebuilt for the current CPU architecture
guix package -m guix/manifests/base.scm

# IMPORTANT: uv (Python) virtual environments are CPU-specific
# Never copy .venv from an x86_64 machine to aarch64; rebuild instead
# cd ... 2>/dev/null || true = change directory, ignore error if it doesn't exist
cd ~/source/repos/qimono-repos/quantum-workspace 2>/dev/null || true

# uv sync = rebuild the Python virtual environment for this CPU
# This downloads pre-built wheels or compiles from source as needed
uv sync   # Alternative: ./scripts/install-quantum-python.sh
```

### 7. Clean unmount

```bash
# exit = leave the qimono-nomad user shell and return to your main user
# This is important before unmounting; otherwise you stay in a folder on the SD card
exit

# umount = safely disconnect the SD card from /home/qimono-nomad
# sync happens automatically, but make sure no processes are using the card
# If you get "Device busy", close any terminals still showing the SD card as current directory
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
