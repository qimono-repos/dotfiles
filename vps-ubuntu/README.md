# vps-ubuntu

Guix-first machine pack for Qimono's headless Ubuntu VPS. This is a server-native
configuration, not a repurposed desktop pack.

## One-command provisioning

From the dotfiles checkout on the VPS:

```bash
cd ~/source/repos/qimono-repos/dotfiles
git pull --ff-only
sudo bash vps-ubuntu/scripts/provision-vps.sh
```

The provisioner installs host prerequisites, installs GNU Guix with the official
installer if needed, initializes channels only on first setup (or with `--refresh-guix`), applies the complete
version-controlled Guix manifest, applies the VPS-native Zsh configuration
through GNU Stow, and prints a machine report without exposing secrets.

Independent stages are failure-isolated. A failed Guix profile application, MongoDB Atlas CLI install, Oh My Posh install, or Stow package application is recorded as a warning and does not automatically prevent unrelated later stages from running. Required host prerequisites and Guix bootstrap remain hard requirements. The final machine report lists optional stages that failed. New independent tools (for example Bun) should be added through the same `run_optional` wrapper rather than allowed to abort the whole convergence run.

The first Guix pull and profile realization are the substantial part of the initial run. Later provisioning reuses the current Guix generation and does not pull again. To deliberately refresh channels, run `sudo bash vps-ubuntu/scripts/provision-vps.sh --refresh-guix`. A stationary progress percentage is not proof of a hung process: use process completion and its exit status as the signal.
Java 21 remains owned by Ubuntu because it is already installed and working. The VPS manifest intentionally excludes `uv` until its package specification is verified against the pinned channel set.

## Important profile policy

`guix package --manifest=...` applies the manifest as the complete profile
generation. Add packages to `guix/manifest.scm` before reapplying it. Do not
use a partial manifest to add one package, or you may remove packages from the
managed profile.

The channel set follows Qimono's established Linux machine packs:
`nonguix + %default-channels`. Nonguix is authenticated with its channel
introduction and its substitute signing key. The provisioner authorizes that
key and uses these substitute servers for pulls and profile realization:

- `https://substitutes.nonguix.org`
- `https://bordeaux.guix.gnu.org`
- `https://ci.guix.gnu.org`

This is intentional: Qimono uses Nonguix for additional and nonfree-adjacent
packages where licensing permits. See
`ubuntu-len-yog-AMD64/docs/LESSONS-guix-browsers.md` for the hard-earned
rules about authenticated channels, selecting the post-pull Guix binary,
substitute keys/URLs, and avoiding source builds on constrained machines.

## Shell / Stow

`stow-source/shell/` is the canonical VPS package. The provisioner migrates
only known legacy symlinks from the earlier HP Pro experiment, backs up an
existing non-Stow `.zshrc`, then links this package into the target home.
Reconnect SSH after provisioning to start in the managed Zsh environment.

Oh My Posh is optional. The prompt configuration degrades gracefully if the
binary is absent. Nerd Font installation belongs on the local terminal client,
not on this headless VPS.

## Codex and OpenCode

The provisioner installs the official MongoDB Atlas CLI (`atlas`) and verifies
its release checksum before installing it. `mongosh` is intentionally omitted
for this VPS milestone: Atlas CLI is sufficient for Atlas project and cluster
management. It does not install a MongoDB server.

Authenticate the Atlas CLI interactively after provisioning:

```bash
atlas auth login
atlas projects list
atlas clusters list
```

The provisioner intentionally does not reconfigure either coding agent.
Existing Codex ChatGPT OAuth credentials are left alone. The provider wiring
script is only for explicit API-key/provider configuration.

With no provider/model selected, `configure-llm.sh` leaves Codex
`config.toml` untouched and never reads or writes `~/.codex/auth.json`.
OpenCode config merging remains separate.

## Layout

- `guix/manifest.scm`: complete VPS user profile.
- `guix/channels.scm`: Nonguix plus the official default channels, authenticated.
- `scripts/install-guix.sh`: official binary installer wrapper.
- `scripts/install-mongodb-tools.sh`: verified Atlas CLI installer; mongosh intentionally omitted.\n- `scripts/install-oh-my-posh.sh`: optional Oh My Posh installer for the Catppuccin Zsh prompt.
- `scripts/provision-vps.sh`: one-command convergence pipeline; no routine channel pulls.
- `scripts/guix-maintenance.sh`: inspect generations, snapshot exact channels, refresh, or roll back.
- `scripts/bootstrap.sh`: compatibility entrypoint to the provisioner.
- `stow-source/shell/`: VPS-native Zsh and prompt configuration.
- `scripts/status.sh`: existing read-only Codex/OpenCode status report.

## Guix maintenance and reproducibility

Use `sudo bash vps-ubuntu/scripts/guix-maintenance.sh status` to inspect Guix state, `snapshot` to write the exact revisions from `guix describe -f channels` to `guix/channels.lock.scm`, `refresh` for a deliberate channel update, or `rollback` to return the Guix command profile to its previous generation. Commit the generated lock file after a successful trusted pull. These operations do not require a server reboot. Logs are appended to `/var/log/qimono-guix-maintenance.log`.

## Safety and scope

- No API keys or MongoDB credentials belong in Git.
- The provisioner never prints environment values or auth files.
- MongoDB Atlas access and the Kotlin/Ktor service are separate deployment
  milestones; this pull does not open Atlas network access or deploy a service.
