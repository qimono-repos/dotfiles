# Flatpak from Guix (ubuntu-mini-pc)

Thin probe: Guix owns the **client**, Flathub owns the **apps**, Ubuntu
still owns the **kernel / AppArmor / portals**. Not a second OS.

Official recipe: <https://flathub.org/en/setup/GNU%20Guix>

## What we did (2026-08-16)

1. Added `"flatpak"` to `guix/manifests/profile-full.scm` (never a lone `-m`).
2. `./scripts/apply-profile.sh` → Guix `flatpak` **1.16.0**.
3. `flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`
4. `flatpak --user -y install flathub com.jeffser.Alpaca` (v9.2.5, GNOME Platform 50).

`which flatpak` is `~/.guix-profile/bin/flatpak`. There is **no** apt `flatpak`.

## The AppArmor gate (foreign-distro only)

Ubuntu 26.04 has `kernel.apparmor_restrict_unprivileged_userns=1` and
path-pins the capable profile to **`/usr/bin/bwrap`**.

Guix Flatpak’s own bubblewrap lives under `/gnu/store/…/bin/bwrap`. First
`flatpak run` without an override:

```
bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted
error: ldconfig failed, exit status 256
```

Kernel audit: `apparmor="DENIED" … profile="unprivileged_userns" comm="bwrap"`
(`setpcap`, `net_admin`).

**Workaround on this Ubuntu host** (does not transfer to a future Guix System):

```bash
export FLATPAK_BWRAP=/usr/bin/bwrap
flatpak --user run com.jeffser.Alpaca
```

That launched Alpaca 9.2.5 (window stayed up). Stow applies the same
variable in:

- `stow-source/shell/.zshrc.d/30-flatpak.zsh` (terminals)
- `stow-source/shell/.config/environment.d/10-qimono-flatpak.conf` (GNOME after login)

A GTK warning about `org.freedesktop.portal.Flatpak` is expected: Ubuntu’s
xdg-desktop-portal does not auto-wire Guix Flatpak’s portal. File pickers
may be limited; chat still starts.

## `alpaca` on the host PATH

Flatpak does **not** install a host `alpaca` binary. The name exists only
inside the sandbox (`--command=alpaca`). Snap used to fake this with
`/snap/bin/alpaca`.

This pack stows `~/.local/bin/alpaca` (already on PATH from `~/.zshrc`):

```bash
alpaca &
# extra args go through, e.g.  alpaca --quick-ask
```

The shim sets `FLATPAK_BWRAP` and `exec`s Guix `flatpak --user run`.
GTK chatter goes to **`/tmp/alpaca-log.txt`** (last 1000 lines kept), same
pattern as HP Pro’s `/tmp/firefox-log.txt`.

```bash
alpaca &                          # clean tty; log in /tmp
tail -f /tmp/alpaca-log.txt       # peek when something is weird
ALPACA_LOG=- alpaca               # rare: keep stderr on the tty
# one-shot without the shim default:
alpaca >/dev/null 2>&1 &          # throw away
```

## Icons (gear vs the animal)

The animal logo **is** in the Flatpak export
(`com.jeffser.Alpaca.svg`). A window launched via raw `flatpak run`
from a session that never saw those icons gets the generic gear.

`scripts/link-flatpak-exports.sh` (also run from `stow-apply.sh`)
symlinks desktop files + icons into `~/.local/share/{applications,icons}`,
which GNOME always searches. Close the geared window and launch again
with `alpaca &` or the Overview tile. A login still helps the session
pick up `environment.d`.

## Ops

```bash
# never sudo, never system remotes
flatpak --user list
flatpak --user update
alpaca &
```

## What this proves for a future Guix System

| Transfers | Does not |
|-----------|----------|
| `guix` package `flatpak` in the profile | Ubuntu AppArmor path-pin |
| `--user` remotes / no root | Need for `FLATPAK_BWRAP=/usr/bin/bwrap` |
| Flathub as the gap-filler store | GNOME Software discovering the apps |

Do **not** `apt install flatpak`. Two clients is the actual box-in-a-box.
