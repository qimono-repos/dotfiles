#!/usr/bin/env bash
set -uo pipefail

hr() {
  printf '\n======== %s ========\n' "$*"
}

hr "Identity"
date -Is
hostname
hostnamectl 2>/dev/null || true
id

hr "OS"
sed -n '1,40p' /etc/os-release 2>/dev/null || true
uname -a

hr "CPU / arch"
uname -m
lscpu 2>/dev/null | sed -n '1,40p' || true
if [[ -e /dev/kvm ]]; then
  echo "/dev/kvm: present"
else
  echo "/dev/kvm: ABSENT"
fi

hr "Memory"
free -h
sed -n '1,10p' /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io 2>/dev/null || true

hr "Storage"
lsblk -o NAME,SIZE,TYPE,FSTYPE,MODEL,TRAN,LABEL,UUID,MOUNTPOINT 2>/dev/null || true
findmnt -R /
df -hT
for dev in /sys/class/block/mmcblk*/device/name; do
  if [[ -r "$dev" ]]; then
    printf 'mmc device name: '
    sed -n '1p' "$dev"
  fi
done

hr "Firmware / boot"
if [[ -d /sys/firmware/efi ]]; then
  echo "firmware: UEFI"
else
  echo "firmware: BIOS"
fi
efibootmgr -v 2>/dev/null | sed -n '1,20p' || true
mokutil --sb-state 2>/dev/null || true
fwupdmgr get-devices 2>/dev/null | sed -n '1,40p' || true

hr "Network"
ip -br a 2>/dev/null || true
ip route 2>/dev/null || true
iw dev 2>/dev/null || true
resolvectl status 2>/dev/null | sed -n '1,40p' || true

hr "Services"
systemctl is-active sshd teamviewerd 2>/dev/null || true
systemctl is-enabled sshd teamviewerd 2>/dev/null || true
firewall-cmd --state 2>/dev/null || true
firewall-cmd --list-all 2>/dev/null || true

hr "Tooling"
for c in guix apt dnf snap podman nix docker stow uv python3 dotnet cargo flatpak gh ssh; do
  if command -v "$c" >/dev/null 2>&1; then
    printf '  OK  %-10s -> %s\n' "$c" "$(command -v "$c")"
  else
    printf '  --  %-10s\n' "$c"
  fi
done

hr "Top processes"
ps -eo pid,user,pcpu,pmem,rss,comm --sort=-rss | sed -n '1,20p'

hr "Done"
echo "machine-discovery finished OK"
