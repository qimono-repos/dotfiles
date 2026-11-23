# fedora/vi-wendy

Machine pack for the legacy Fedora notebook **`vi-wendy`** (EXO Smart E16Plus, Intel Atom x5-Z8350, x86_64).

This pack records what the host actually is, what it is fit for, and how to refresh the evidence. It deliberately does **not** claim this notebook is a server or a full Guix System candidate.

## Current status

- Fedora 35 Workstation, kernel 5.18.5 — EOL.
- 3.7 GiB RAM, 29.1 GB eMMC, ~9.4 GiB free at snapshot.
- UEFI with Secure Boot disabled; removable boot available.
- Wi-Fi only; no wired Ethernet observed.
- `sshd` disabled; GitHub SSH access verified.
- Battery discharge monitor active as a user service; see [`BATTERY-MONITOR.md`](./BATTERY-MONITOR.md).
- TeamViewer removed; see [`TEAMVIEWER-REMOVAL.md`](./TEAMVIEWER-REMOVAL.md).
- `too` / `powerofff` available as bash functions; see [`TOO.md`](./TOO.md).
- Guix System 1.5.0 ISO + Etcher staged for first-citizen migration; see [`GUIX-MIGRATION.md`](./GUIX-MIGRATION.md).
- Recommended role: Guix System first-citizen candidate; Fedora remains until the installer overwrites it.

## Layout

```text
fedora/vi-wendy/
  README.md                    this file
  MACHINE.md                   hardware/software snapshot + role assessment
  GITHUB.md                    GitHub/Git/gh access notes (no secrets)
  BATTERY-MONITOR.md           unplugged runtime measurement
  TEAMVIEWER-REMOVAL.md        sudo cleanup + verification
  GUIX-MIGRATION.md            staged Guix 1.5 ISO + Etcher, flashing gate
  TOO.md                       bash port of the emergency too/powerofff commands
  shell/50-power.sh            bash functions sourced from ~/.bashrc.d
  scripts/machine-discovery.sh read-only host probe
  scripts/install-github-cli.sh idempotent user-owned gh installer
  scripts/install-too.sh       bash functions + narrow passwordless power sudoers
  scripts/remove-teamviewer.sh root-owned package/service cleanup
  scripts/battery-monitor.sh   UPower CSV logger + estimates
  systemd/                     user service unit
  inventory/                   timestamped discovery snapshots
  QA/                          Human + AI acceptance checks
```

## Refresh

```bash
cd ~/source/repos/qimono-repos/dotfiles
./fedora/vi-wendy/scripts/machine-discovery.sh | tee \
  "fedora/vi-wendy/inventory/vi-wendy-$(date +%Y-%m-%d).txt"
```

The discovery script is read-only: no mounts, package installs, writes outside its own stdout, or secret output. The repository is public, so redact machine/boot IDs, local IPs, Wi-Fi SSID, and MAC addresses in any snapshot before committing it.

## Safety boundaries

- Do not install Guix System over this Fedora/eMMC install without the explicit destructive-migration gate. Use removable media first.
- Do not enable `sshd` for a production role until the OS is supported and firewall rules are reviewed.
- Do not reuse root `sat-*` aliases from `../../ssh/config` without documenting the hosts.
- Do not treat `/dev/kvm` as permission to run heavy VMs on 3.7 GiB RAM.

## Related

- Root pack index: [`../../README.md`](../../README.md)
- Guix lobby design: [`../../GUIX-OS-AS-LOBBY.md`](../../GUIX-OS-AS-LOBBY.md)
- Lobby post-install notes: [`../../lobby-files/README.md`](../../lobby-files/README.md)
- Original fleet `too` design: [`../../ubuntu-mini-pc/README_TOO.md`](../../ubuntu-mini-pc/README_TOO.md)
