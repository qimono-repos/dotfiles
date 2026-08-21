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
