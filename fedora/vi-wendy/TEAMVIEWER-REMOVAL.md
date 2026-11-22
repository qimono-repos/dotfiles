# TeamViewer removal — vi-wendy

Goal: remove a stale remote-control path and reclaim space on the 29.1 GB eMMC.

## State at 2026-11-22

| Item | State |
|------|-------|
| Installed package | `teamviewer-15.30.3-0.x86_64` |
| Package size reported by RPM | ~267 MB |
| Service | `teamviewerd.service`, enabled + active, listening on `127.0.0.1:5939` |
| Local installer | `~/teamviewer.x86_64.rpm`, 64 MB |
| User config | `~/.config/teamviewer`, 4 KB |
| YUM repo | `/etc/yum.repos.d/teamviewer.repo` (package-owned) |

The user-owned installer and config were removed already. The package and service require root.

## Root cleanup

Use an absolute path with `sudo bash` so the current directory and executable bit cannot break the command:

```bash
sudo bash /home/wendy/source/repos/qimono-repos/dotfiles/fedora/vi-wendy/scripts/remove-teamviewer.sh
```

The script stops and disables the service, removes the package, cleans known residual paths, reloads systemd, and prints verification output. It disables the two broken third-party repos seen on this host during `dnf` metadata refresh.

## Manual equivalent

```bash
sudo systemctl disable --now teamviewerd.service
sudo dnf -y --disablerepo=anydesk --disablerepo=phracek-PyCharm remove teamviewer
sudo rm -rf /opt/teamviewer /etc/teamviewer /etc/yum.repos.d/teamviewer.repo
sudo systemctl daemon-reload
```

Use `sudo rpm -e teamviewer` only if `dnf` cannot resolve metadata; avoid `--nodeps` unless the dependency error has been read and accepted.

## Verification

```bash
rpm -qa '*teamviewer*'
systemctl status teamviewerd.service --no-pager
ss -tulpen | grep teamviewer || true
df -h /
```

Expected: no package, unit not found or inactive, no listener, and ~330 MB more free space than before.

## Firewall note

The active `FedoraWorkstation` zone allows ports `1025-65535/tcp,udp`. That is broader than this remote-control cleanup and should be reviewed separately before any server role is considered.
