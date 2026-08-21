# Flatpak from Guix (ubuntu-len-yog-AMD64)

Same pattern as `ubuntu-mini-pc/docs/flatpak-guix.md`: Guix owns the
**client**, the remote owns the **apps**, Ubuntu owns kernel/AppArmor/
portals. First app landed: **Ghostty** (2026-08-21).

## Client install (this host)

`flatpak 1.16.6` added to `guix/manifests/profile-full.scm`, then applied
transactionally (`guix package -r zlib -i flatpak -u epiphany`) because the
ad-hoc profile had mixed-generation zlib store paths (conflict vs flatpak's
propagated zlib, then vs epiphany's). A future clean `-m` apply makes this a
non-issue. Explicit `zlib` left the profile but stays via propagation.

## Why not Flathub for ghostty

Flathub has **no ghostty** (0 results; see ghostty discussion #3201).
Ranks tried in order: Guix (not packaged) → Flathub-via-Guix (absent) →
apt/snap (policy-rejected) → **unofficial signed Flatpak repo**, which keeps
the Guix-client pattern intact:

```bash
# done 2026-08-21 — records only
flatpak --user install -y https://adonm.github.io/ghostty-flatpak/ghostty.flatpakref
```

- App id `com.mitchellh.ghostty`, v1.3.1, origin `adonm-ghostty`
- Built by GitHub Actions from official stable source archives using the
  upstream manifest; repo commits GPG-signed,
  fp `EC55 4811 2CA7 B023 735B 36D1 8EB0 9A34 C1E2 3C49`
- Runtime (`org.gnome.Platform` 49) still comes from Flathub
- Updates ride normal `flatpak --user update`

## Gotchas found (cost us an hour — read before debugging)

1. **Sandbox XDG**: flatpak sets `XDG_CONFIG_HOME=~/.var/app/<app-id>/config`,
   so ghostty NEVER reads host `~/.config/ghostty/*`. Stow alone is not enough.
   Fix: `scripts/link-ghostty-appdir.sh` (wired into `stow-apply.sh`) symlinks
   `~/.var/app/com.mitchellh.ghostty/config/ghostty/config → stow-source/shell/.config/ghostty/config`.
2. **Dual filename**: ghostty 1.3.x probes BOTH `config` and `config.ghostty`
   in that dir and loads both if present (debug log proves it). The mini-pc
   pack's `config.ghostty` name is therefore valid too — earlier assumption
   that it was ignored was wrong for ≥1.3.
3. **Broken CLI probe**: in this build `ghostty +show-config` (diff mode)
   exits 1 silently even with zero user config; `+show-config --default`
   works. Validate configs with
   `+validate-config [--config-file=…]` instead.
4. `FLATPAK_BWRAP=/usr/bin/bwrap` plumbing is stowed (`.zshrc.d/35-flatpak.zsh`,
   `.config/environment.d/10-qimono-flatpak.conf`). This host already has
   `apparmor_restrict_unprivileged_userns=0` persisted, and client ops worked
   without it — kept anyway for fleet parity.
5. **D-Bus activation gap (2026-08-21)**: Guix owns the client, so its helper
   daemons live in `$GUIX_PROFILE/share/dbus-1/services/` — invisible to the
   systemd user bus (`XDG_DATA_DIRS` there lacks the Guix profile; 10-guix.zsh
   only fixes interactive shells). Sandboxed terminals die instantly:
   `Flatpak.HostCommand failed … ServiceUnknown → error.FlatpakSpawnFail`
   (GNOME tile "does nothing"; also NO `ghostty` on PATH — Flatpak apps ship
   no binary). Fix, all idempotent via `stow-apply.sh`:
   - `scripts/link-flatpak-host-services.sh` writes activation files to
     `~/.local/share/dbus-1/services/` pointing at stable
     `~/.guix-profile/libexec/flatpak-{session-helper,portal}` symlinks.
     dbus hot-reloads the dir — no logout needed (verified live).
   - `stow-source/shell/.local/bin/ghostty` shim (alpaca pattern) for CLI use.
   - Config `command` runs **ON THE HOST** already (the build spawns it via
     the portal: "started subcommand on host via flatpak API"). So use a
     plain absolute path: `command = /usr/bin/zsh -l`. Do NOT wrap in
     `flatpak-spawn --host` — that binary exists only inside runtimes, so
     the host-side `/bin/sh -c` fails (`flatpak-spawn: not found`), ghostty
     falls back to a login `/bin/sh`, and dash then chokes on any
     `source` in `~/.profile` (`/bin/sh: 31: source: not found`). Absolute
     path matters because activation env may carry a minimal PATH.
     Probe: `pgrep -fa 'zsh -l'` must show the shell under the app scope.
   - **GNOME clicks use D-Bus activation, never Exec** (desktop file has
     `DBusActivatable=true`): Shell asks the bus for name `com.mitchellh.ghostty`,
     and if no activation file is visible it fails SILENTLY ("tile does
     nothing") while direct `flatpak run` works fine — classic misleading
     symptom. Flatpak exports the needed file under
     `exports/share/dbus-1/services/`, which the bus also can't scan.
     `link-flatpak-host-services.sh` therefore symlinks ALL exported app
     service files into `~/.local/share/dbus-1/services/` (through stable
     `current/active` paths so they survive app updates). New files may need
     `systemctl --user reload dbus` (or relogin) to become activatable;
     verify with `gdbus call --session --dest org.freedesktop.DBus \
     --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.ListActivatableNames`.
     Click-path probe without GNOME: `gtk-launch com.mitchellh.ghostty`.
   Fleet note: mini-pc will hit this too if it ever installs a terminal-emulator
   Flatpak; plain GUI apps (Alpaca) never need HostCommand and are unaffected.

## Ops

```bash
export GUIX_PROFILE="$HOME/.guix-profile"; . "$GUIX_PROFILE/etc/profile"
flatpak --user list                      # ghostty lives here, never sudo
flatpak --user update                    # picks up new adonm stable builds
flatpak run com.mitchellh.ghostty        # or the GNOME launcher tile
```

Launcher tile/icon come from `scripts/link-flatpak-exports.sh`; the config
link from `scripts/link-ghostty-appdir.sh`; both re-run via
`./scripts/stow-apply.sh`.
