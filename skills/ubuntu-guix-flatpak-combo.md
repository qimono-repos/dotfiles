# Skill: Ubuntu + Guix + Flatpak combo

> Distilled from the Ghostty launch saga (2026-08-21, qimono-localhost).
> Goal: any future Flatpak package install works on the FIRST run.
> Full post-mortem: `ubuntu-len-yog-AMD64/docs/flatpak-guix.md` (gotchas #1–5).

## When to use this skill

Installing or debugging ANY Flatpak app on a foreign-distro machine
(Ubuntu) where Flatpak is owned by Guix (manifest: `flatpak`), i.e.:

- Client binary is `~/.guix-profile/bin/flatpak` — NEVER `apt install flatpak`
- App data lands in `~/.local/share/flatpak/`, runtimes in `~/.local/share/flatpak/runtime`
- Desktop exports in `~/.local/share/flatpak/exports/share/`

## The 8 laws of this combo

1. **One client only.** Guix's flatpak. An apt flatpak would fight over
   `$XDG_DATA_HOME/flatpak` and system helpers. Do not apt-install it.
2. **Flatpak apps ship no PATH binary.** CLI access needs a stow shim
   (pattern: `stow-source/shell/.local/bin/ghostty`, alpaca precedent).
   `flatpak run <app-id>` always works; find ids with
   `flatpak list --app --columns=application,name`.
3. **The session bus cannot see the Guix profile.** systemd-user env lacks
   `$GUIX_PROFILE/share` in `XDG_DATA_DIRS` (zshrc fixes shells only). Every
   D-Bus activation file under `exports/share/dbus-1/services/` AND the two
   client helpers (`org.freedesktop.Flatpak`, `org.freedesktop.portal.Flatpak`)
   are therefore invisible until linked into `~/.local/share/dbus-1/services/`.
   → `scripts/link-flatpak-host-services.sh` does ALL of this, idempotently.
4. **GNOME clicks never run Exec when `DBusActivatable=true`.** The tile asks
   the bus for name `<app-id>`; unknown name = SILENT nothing. Meanwhile
   direct `flatpak run` works fine — misleading symptom pair.
5. **Sandbox XDG redirect.** Config goes to
   `~/.var/app/<app-id>/config/...`; stow alone is not enough.
   → `scripts/link-ghostty-appdir.sh` pattern (per-app link script wired into
   `stow-apply.sh`).
6. **Terminal-emulator `command` runs ON THE HOST** via the spawn portal
   ("subcommand on host via flatpak API"). Use a plain absolute host path:
   `command = /usr/bin/zsh -l`. NEVER wrap with `flatpak-spawn --host` — that
   binary exists only inside runtimes; wrapping breaks host exec and ghostty
   falls back to login `/bin/sh`, which trips on `source` in `~/.profile`.
7. **bwrap must be the Ubuntu one:** `FLATPAK_BWRAP=/usr/bin/bwrap`
    (AppArmor blesses only that path on this host; set via
   `.config/environment.d/10-qimono-flatpak.conf`). Session-level env belongs
   in environment.d — the user manager never reads zshrc.
   **TRAP:** `${XDG_DATA_DIRS}` (or any pam/gnome-session-provided var)
   expands to EMPTY inside environment.d — the user manager starts before
   anything populates it. An "append" is really replace-and-wipe; wiping
   `/usr/share` kills GSettings schema lookup and GNOME sessions abort on
   login ("No GSettings schemas are installed on the system", 2026-08-21
   Yoga login loop). environment.d values must be ABSOLUTE and
   self-contained.
8. **New D-Bus service files may need** `systemctl --user reload dbus`
   (or relogin) before they become activatable.

## First-run install checklist

```bash
# 0. discover machine state
scripts/machine-discovery.sh          # or read docs first

# 1. add app to guix manifest if needed, then: guix pull && guix package -m ...
~/.guix-profile/bin/flatpak remotes   # repo present? else remote-add (signed URL)
~/.guix-profile/bin/flatpak install <app-id>

# 2. wire everything (idempotent, covers laws 3+5+7)
./scripts/stow-apply.sh               # runs link-flatpak-exports + host-services + app links

# 3. make activation visible NOW (or log out/in once)
systemctl --user reload dbus

# 4. verify BEFORE telling anyone it works
gdbus call --session --dest org.freedesktop.DBus \
  --object-path /org/freedesktop/DBus \
  --method org.freedesktop.DBus.ListActivatableNames | tr ',' '\n' | grep -i <app-id>
gtk-launch <app-id> &                 # exact GNOME click path
systemctl --user list-units 'app-flatpak*' --no-legend   # scope stays 'running'
```

## Symptom → cause table (learned the hard way)

| Symptom | Cause | Fix |
|---|---|---|
| Tile click: silent nothing; direct `flatpak run` works | Law 4 — activation file invisible | law 3 script + law 8 reload |
| Window opens, dies instantly; journal shows `ServiceUnknown`, `FlatpakSpawnFail` | helper services missing | law 3 |
| `<app>: command not found` in terminal | no CLI shim | law 2 |
| Terminal window opens but `/bin/sh: N: source: not found` and/or `flatpak-spawn: not found` | config `command` wrongly wrapped in `flatpak-spawn` while executing ON THE HOST | law 6 |
| Shell falls back to plain `sh` prompt inside terminal emulator | command path not found by spawned sh | absolute path, law 6 |
| "directories not in XDG_DATA_DIRS" note every login shell | session env lacks exports dirs | environment.d entry (law 7) |
| `ldconfig` exit 256 / bwrap exec denied | store-path bwrap blocked by AppArmor | law 7 |
| GDM accepts password then loops back; journal: `gnome-session-manager … No GSettings schemas … core-dump` | environment.d "appended" to empty `${XDG_DATA_DIRS}`, wiping `/usr/share` | law 7 trap — hardcode absolute list |

## Debug toolkit

```bash
journalctl --user -b --grep -i '<app-id>'        # scope churn, spawn errors
busctl --user status <app-id>                    # who owns the name
GDK_DEBUG=all gtk-launch <app-id>                # gio launch path w/o GNOME Shell
env -i HOME=$HOME PATH=/usr/bin:/bin ... gtk-launch …   # simulate tile env
# capture what the app's shell actually sees:
# temporarily set command=/bin/sh -c 'env > /tmp/zenv' then relaunch via tile
```

## Fleet note

mini-pc inherits this skill automatically IF its `stow-apply.sh` also calls
`link-flatpak-host-services.sh`. Plain GUI apps (Alpaca) never need
HostCommand; only terminal emulators and CLI-shimmed apps exercise laws 2/6.
