# Apple Container — researched facts (verified 2026-08-31)

What drives this pack. Contains only things we verified or that Apple/Mainals
documented; open-items flagged `[OPEN]`.

## What it is

- **`container` CLI + `Containerization` Swift framework** — open-sourced at
  WWDC 2025, Apache-2.0. Each Linux container runs inside its **own lightweight
  VM** (Virtualization.framework) — daemonless, battery-friendly, isolated.
- **v1.0.0 released 2026-06-09**; current stable ~v1.3.1 (44k+ GitHub stars).
- Speaks OCI — images build/run like anywhere else.

## Hard requirements

- **Apple Silicon only** (M1+; we have M3).
- **macOS 26 "Tahoe" minimum.** Sequoia (15) / GoldenGate are **not** supported —
  networking breaks. This is the very first step on day 1.
- Building images needs **Rosetta 2** (`/usr/bin/pgrep -> Rosetta`). Actual
  execution is native arm64.

## Install

```bash
brew install container        # formula exists (arm64, macOS>=26) — [OPEN] verify tap
container system start        # first run: prompts to install a Linux kernel
container --version
```

Fallback if the formula is missing/pinned: download the signed `.pkg` from
`github.com/apple/container` Releases (has uninstall-container.sh etc.).

## Container machines (the WWDC26 star)

- **Persistent, stateful Linux environments** — boot the image's OWN init
  (`/sbin/init`, e.g. systemd) as PID 1 (NOT vminitd). Sub-second start, VM-class
  persistence.
- **Mirror macOS `$HOME` live** via VirtioFS (same user, same path) — your
  repos, SSH keys, dotfiles are already inside Linux. The Guix profile lives in
  `$HOME` and survives machine restarts.
- Config is **TOML** (`container config`); machines managed via
  `container machine` (`create --name qi-dev --set-default <image>`, `list`,
  `run <name>`). `run` gives a stateful shell in the machine.

## Traps (from verified first-adopter reports)

1. **Upstream Ubuntu/Debian images FAIL** as machine bases — they have no init
   at `/sbin/init`. Alpine works out of the box. For systemd you build your own
   image: `FROM debian:bookworm`, `ENV container container`, mask breakers,
   empty `/etc/machine-id`, real init at `/sbin/init`.
2. **Username/`$HOME` mirroring had a v1.0 race** — if flaky, **recreate** the
   machine, do not migrate state.
3. First `container system start` downloads a Linux kernel (one-time).
4. Podman is a different VM model (`podman machine`); it's parity/CI, not the
   daily driver.
5. `[OPEN]` exact `container machine` flag syntax may drift between v1.3.x
   releases — `container machine --help` before scripting.

## Why this beats bare meltdown on macOS for us

Guix has no native macOS; a container machine is real Linux where Guix is
supported — and `$HOME` sharing means zero copy-paste for dotfiles/keys.