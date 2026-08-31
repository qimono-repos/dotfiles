# darwin

Shared Qimono machine pack for the **2026 Apple Silicon fleet** — a
**MacBook Air** and a **Mac mini**. This pack is shared across both Macs
(herd, not per-machine), per the fleet decision on 2026-08-31.

The FIVE-layer stack (see [docs/apple-container.md](./docs/apple-container.md)):

| Layer | Tool | Role |
|-------|------|------|
| OS (gate) | **macOS 26 "Tahoe"** | Apple Container requires it; Sequoia breaks |
| Host manager | **Homebrew** (`/opt/homebrew`) | CLI tools + casks |
| Linux runtime | **Apple `container`** (Apache-2.0, v1.0+) | OCI containers, each in its own lightweight VM |
| Persistent Linux dev env | **container machine** — custom Debian image w/ systemd | stateful Linux, `$HOME` mirrored live via VirtioFS |
| Your Guix | **Guix inside the machine** (foreign-distro mode) | real GNU Guix where it is supported |
| Fallback/parity | **Podman** | cross-platform, CI/server parity |

**Asahi Linux** (dual-boot) remains the "happy ending" ambition — deferred,
not the day-1 path. Keep the APFS volume shrinkable in your plans.

## Why Guix-in-a-container-machine (not Guix-on-macOS)

- GNU Guix has **no maintained native macOS port**; `aarch64-darwin` is a
  cross-compile target only.
- Guix is first-class on Linux. The container machine is Linux (Debian-based),
  so `guix install`, `guix shell`, `guix package -m`, channels and manifests
  all work unchanged — matching the 2024 M1 MacBook experience.
- The machine **mirrors macOS `$HOME` live**, so your dotfiles (stowed from
  this pack), SSH keys and repos are already inside Linux; the Guix profile
  symlink lives in `$HOME` and survives machine restarts.

## Package-manager ranking (this pack)

| Rank | Manager | Role when it wins |
|------|---------|-------------------|
| **1** | **brew** | Everything on the macOS host (Host) |
| **2** | **Guix** | Inside the container machine (Dev): CLI, Python, editors, manifests |
| **3** | **apt** | Inside the container machine (System): kernel-adjacent, daemons |
| **4** | **podman** | Portability/CI parity (daemonless; same philosophy as Apple container) |

## Layout

```
darwin/
  README.md
  MACHINE.md                # filled from machine-discovery.sh after acquisition
  QA/                       # Human + AI split checklists (like the Linux packs)
  docs/
    apple-container.md      # researched facts + traps (verified 2026-08-31)
    guix-in-container.md    # Guix foreign-distro bootstrap inside the machine
  guix/
    channels.scm            # mirrors gnu-guix/config/guix/channels.scm (nonguix)
    manifests/
      darwin-base.scm       # Guix profile for inside the machine
  scripts/
    bootstrap.sh            # host orchestrator (called by fleet/brew.sh)
    machine-discovery.sh    # macOS probe (sysctl hw.model, sw_vers, brew, container)
    install-container.sh    # brew container + podman + container system start
    container-machine-create.sh  # Debian+systemd image → container machine create
    gen-guix-in-container.sh     # writes guest bootstrap into the mirrored $HOME
    stow-apply.sh
  stow-source/shell/        # shared zsh + oh-my-posh + ghostty (OS-guarded snippets)
  tests/smoke-tests/        # in-machine smoke checks
```

## Quick start (both Macs, in parallel)

```bash
cd ~/source/repos/qimono-repos/dotfiles/darwin

# 0) Update macOS to 26 (Tahoe) first — hard gate.
# 1) Host stack (CLT → brew → bundle → container → podman → machine):
./scripts/bootstrap.sh

# 2) Generate the Guix-in-container bootstrap into $HOME (mirrored into Linux):
./scripts/gen-guix-in-container.sh

# 3) Enter the dev machine and bootstrap Guix (runs INSIDE the machine):
container machine run qi-dev
sudo bash ~/.qimono/guix-in-container.sh    # inside the machine
```

Stow is applied by `bootstrap.sh`; re-apply anytime with
`./scripts/stow-apply.sh`.

## Sibling machines

| Host pack | Platform | Notes |
|-----------|----------|-------|
| `darwin` (this) | Apple Silicon macOS 26 | MacBook Air (M3) + Mac mini (M3) |
| `ubuntu-len-yog-ARM64` | aarch64 Linux | Snapdragon Yoga (the box this was authored on) |
| `ubuntu-len-yog-AMD64` | x86_64 Linux | AMD Yoga 7 |
| `ubuntu-hp-pro` | x86_64 Linux | Intel ProBook 440 G9 |
| `ubuntu-mini-pc` | x86_64 Linux | Ryzen 7 7730U |
| `fedora` | x86_64 Linux | standalone |
| `windows11` | x86_64 Windows | winget |

## Day-1 note

Append a **Session log** line to `JOURNAL-P3-P5.md` and commit the pack after
the first successful `QA` pass on both Macs.