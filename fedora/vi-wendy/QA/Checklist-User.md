# QA — User (fedora/vi-wendy)

**Pair:** [Checklist-agent.md](./Checklist-agent.md) · **Hub:** [README.md](./README.md)

## U1 — GitHub access

- [ ] SSH key added to the correct GitHub account.
- [ ] `ssh -o BatchMode=yes -T git@github.com` says `Hi qimono-repos!`.
- [ ] `git ls-remote origin HEAD` succeeds.
- [ ] `gh auth login` completed if `gh` commands are needed.

## U2 — TeamViewer removal

- [ ] Read `../TEAMVIEWER-REMOVAL.md`.
- [ ] Run `sudo bash /home/wendy/source/repos/qimono-repos/dotfiles/fedora/vi-wendy/scripts/remove-teamviewer.sh`.
- [ ] `rpm -qa '*teamviewer*'` is empty.
- [ ] `systemctl status teamviewerd.service` shows not found or inactive.
- [ ] No TeamViewer listener remains in `ss -tulpen`.
- [ ] `df -h /` shows reclaimed space.

## U3 — After cleanup

- [ ] Reboot once and confirm the daemon did not return.
- [ ] Confirm GitHub SSH still works after reboot.
- [ ] Decide whether to narrow the firewall `1025-65535` port range.
- [ ] Refresh the inventory snapshot if hardware/OS changed.

## U5 — Battery runtime

- [ ] `systemctl --user status qimono-battery-monitor.service` shows active.
- [ ] Summary file updates on the configured interval.
- [ ] Log a plug-in/plug-out event with its timestamp when charge cycles change.
- [ ] Do not reboot or plug in AC while measuring unplugged runtime.
- [ ] After shutdown at 0%, copy the CSV into the inventory folder or summarize the measured runtime.

## U4 — Role boundary

- [ ] Do not enable `sshd` for production until OS/network/firewall gates are met.
- [ ] Do not install Guix System directly onto the eMMC.
- [ ] Use removable media for Guix lobby experiments.
