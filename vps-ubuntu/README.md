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
installer if needed, pulls the official channel, applies the complete
version-controlled Guix manifest, applies the VPS-native Zsh configuration
through GNU Stow, and prints a machine report without exposing secrets.

The first Guix pull and profile realization are the substantial part of this
run. On a 1-vCPU VPS, download/build time depends on substitute availability.
Java 21 remains owned by Ubuntu because it is already installed and working.

## Important profile policy

`guix package --manifest=...` applies the manifest as the complete profile
generation. Add packages to `guix/manifest.scm` before reapplying it. Do not
use a partial manifest to add one package, or you may remove packages from the
managed profile.

The initial channel list contains GNU Guix only. Nonguix is deliberately not
enabled by default.

## Shell / Stow

`stow-source/shell/` is the canonical VPS package. The provisioner migrates
only known legacy symlinks from the earlier HP Pro experiment, backs up an
existing non-Stow `.zshrc`, then links this package into the target home.
Reconnect SSH after provisioning to start in the managed Zsh environment.

Oh My Posh is optional. The prompt configuration degrades gracefully if the
binary is absent. Nerd Font installation belongs on the local terminal client,
not on this headless VPS.

## Codex and OpenCode

The provisioner intentionally does not reconfigure either coding agent.
Existing Codex ChatGPT OAuth credentials are left alone. The provider wiring
script is only for explicit API-key/provider configuration.

With no provider/model selected, `configure-llm.sh` leaves Codex
`config.toml` untouched and never reads or writes `~/.codex/auth.json`.
OpenCode config merging remains separate.

## Layout

- `guix/manifest.scm`: complete VPS user profile.
- `guix/channels.scm`: official channel definition.
- `scripts/install-guix.sh`: official binary installer wrapper.
- `scripts/provision-vps.sh`: one-command convergence pipeline.
- `scripts/bootstrap.sh`: compatibility entrypoint to the provisioner.
- `stow-source/shell/`: VPS-native Zsh and prompt configuration.
- `scripts/status.sh`: existing read-only Codex/OpenCode status report.

## Safety and scope

- No API keys or MongoDB credentials belong in Git.
- The provisioner never prints environment values or auth files.
- MongoDB Atlas access and the Kotlin/Ktor service are separate deployment
  milestones; this pull does not open Atlas network access or deploy a service.
