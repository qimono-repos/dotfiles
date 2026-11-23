# `too` — Turn Off and On again (vi-wendy)

`too` is the Qimono emergency reboot command: force reboot now, ignore GNOME/session inhibitor locks, ask no confirmation, and lose unsaved work. `powerofff` is the matching force poweroff command.

The original fleet implementation is a **zsh** function in `ubuntu-mini-pc/stow-source/shell/.zshrc.d/50-power.zsh`. `vi-wendy` uses **bash** and has no `zsh` installed, so running `too` there gives `too: command not found` until this bash port is installed.

It must be a shell function, not an alias: `sudo` does not expand aliases. Elevation lives inside the function.

## Install

```bash
sudo bash /home/wendy/source/repos/qimono-repos/dotfiles/fedora/vi-wendy/scripts/install-too.sh
```

The installer:

- copies `shell/50-power.sh` to `~/.bashrc.d/50-power.sh` for `wendy`;
- confirms `~/.bashrc` already sources `~/.bashrc.d` (it does on this host);
- installs `/etc/sudoers.d/qimono-power`, mode `0440`, validated with `visudo -cf`;
- grants passwordless sudo only for `/usr/bin/systemctl reboot -i` and `/usr/bin/systemctl poweroff -i`.

No packages are installed. No other sudo rights are added.

## Use

Open a **new** bash shell, then:

```bash
type too
sudo -n -l | grep systemctl
```

When needed:

```bash
too
```

or, to power off instead:

```bash
powerofff
```

If `too` still prompts for a password, run `sudo -k`, open a fresh shell, and check that `/etc/sudoers.d/qimono-power` exists.

## Safety

- `too` is deliberately immediate: no confirmation, no graceful shutdown, unsaved work lost.
- Do **not** use `too` while the battery runtime measurement is active unless you intend to end the test; see [`BATTERY-MONITOR.md`](./BATTERY-MONITOR.md).
- Physical power cycle remains the last resort.

## Scope

This is a `vi-wendy` bash port of the existing fleet convention documented in [`../../ubuntu-mini-pc/README_TOO.md`](../../ubuntu-mini-pc/README_TOO.md). The documented `too --info`, SSH broadcast, and Git emergency-save features are proposals only and are not implemented here.
