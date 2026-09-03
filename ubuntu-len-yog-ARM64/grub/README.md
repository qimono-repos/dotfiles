# GRUB — dual-boot (Ubuntu ⇄ Windows 11) on the Snapdragon Yoga

`grub-optimizer` / `grub-customizer` are **not packaged** for this aarch64
Ubuntu 26.04 (absent from both Guix and apt). This pack mimics exactly what
grub-optimizer would do, as plain stow-able text — the safest, most
reviewable route for a BitLocker dual-boot host.

## What it does

- **Shows a GRUB menu** (was `GRUB_TIMEOUT=0 hidden` → boots straight to Ubuntu).
- **Enables os-prober** → detects **Windows 11** (BitLocker, `nvme0n1p3`).
- **`GRUB_DISABLE_SUBMENU=y`** → flattens the submenu so Windows is pickable
  directly.
- Provides a **manual chainload stub** (`40_custom.windows-chainload`) as a
  belt-and-braces fallback if os-prober is flaky with BitLocker.

## Install (needs sudo; do it in a real terminal where you can type a password)

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-ARM64
sudo ./scripts/apply-grub.sh
# → installs /etc/default/grub.d/99-qimono-grub.cfg
# → prints the Windows chainload template; APPEND it to /etc/grub.d/40_custom
# → runs update-grub (probes Windows)
```

Then verify before committing:

```bash
sudo os-prober            # should list Microsoft Windows 11 …
grep -i mention /boot/grub/grub.cfg | head   # Windows entry present?
```

Reboot — choose Ubuntu or Windows from the 8s menu.

## Files

| File | Role |
|------|------|
| `grub/stow-source/etc/default/grub.d/99-qimono-grub.cfg` | the run config override (grub-optimizer equivalent) |
| `grub/stow-source/etc/grub.d/40_custom.windows-chainload` | template — append into `/etc/grub.d/40_custom` if you want the deterministic EFI entry |
| `scripts/apply-grub.sh` | sudo helper that installs the above + runs `update-grub` |

## Why not grub-optimizer

- Not in Guix, not in apt on aarch64 (this is an arm64 host; the tool is x86+NRGUI).
- grub-optimizer rewrites `/etc/default/grub` wholesale; hand-rolling the
  ~10 lines we need is more reviewable and just as effective for a 2-OS config.

## BitLocker note

os-prober mounts the Windows partition read-only to read the BCD store. With
BitLocker, the partition is encrypted; modern os-prober (2.14) still detects
Windows by probing the EFI/BCD metadata it can read, so this normally works.
If it doesn't, use the manual chainload entry above — it bypasses the BCD
read entirely by chaining the Windows EFI loader from the ESP.
