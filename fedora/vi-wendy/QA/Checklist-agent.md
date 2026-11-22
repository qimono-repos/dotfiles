# QA — Agent (fedora/vi-wendy)

**Pair:** [Checklist-User.md](./Checklist-User.md) · **Hub:** [README.md](./README.md)

## A1 — Pack integrity

- [ ] `MACHINE.md` matches the latest discovery snapshot.
- [ ] `scripts/machine-discovery.sh` is read-only and passes `bash -n`.
- [ ] `GITHUB.md` contains no private keys or tokens.
- [ ] `scripts/install-github-cli.sh` is idempotent and checksum-verified.
- [ ] `TEAMVIEWER-REMOVAL.md` documents both script and manual paths.
- [ ] Root `README.md` links the pack.

## A2 — Evidence discipline

- [ ] Do not call this host a server-manager candidate.
- [ ] Do not call this host a 100% Guix System candidate.
- [ ] Record VT-x/`/dev/kvm` as capability, not performance capacity.
- [ ] Record EOL Fedora 35 and Wi-Fi-only networking as blockers.
- [ ] Treat Guix lobby use as removable-media-only.

## A3 — Access verification

- [ ] `git remote -v` shows `git@github.com:qimono-repos/dotfiles.git`.
- [ ] `ssh -o BatchMode=yes -T git@github.com` identifies `qimono-repos`.
- [ ] `git ls-remote origin HEAD` succeeds.
- [ ] GitHub host keys were verified against the GitHub API.

## A4 — TeamViewer cleanup support

- [ ] User-owned installer and config removal is recorded.
- [ ] Root cleanup script is present and shell-syntax clean.
- [ ] No token, password, or private key is requested by the script.
- [ ] Firewall port review is left as a separate human decision.

## A5 — Battery monitor

- [ ] `scripts/battery-monitor.sh` is executable and passes `bash -n`.
- [ ] `systemd/qimono-battery-monitor.service` points at the repo script.
- [ ] `systemctl --user is-active qimono-battery-monitor.service` is `active`.
- [ ] CSV and summary paths are outside the repository.
- [ ] No root or linger is required, so the service stops at logout.
- [ ] Estimates distinguish UPower short-term rate from observed average rate.

## Sign-off

| Field | Value |
|-------|-------|
| Date | |
| Host | vi-wendy |
| Snapshot file | |
| TeamViewer absent? | |
| Notes | |
