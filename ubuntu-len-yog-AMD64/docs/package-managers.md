# Package manager policy

## Ranking (aspirational, not law)

This is a **wishable order** when real availability and effort allow — not an authoritative ban list.  
**Stage 1** (now): Guix *on* Ubuntu. **Later:** Guix *as* OS; apt/snap gone; Podman + Nix experience still valuable.

| Rank | Manager | When it wins |
|------|---------|--------------|
| **1** | **GNU Guix** | Userland, manifests, channels, reproducible profiles |
| **2** | **apt** | Kernel, firmware, desktop, systemd-integrated host bits |
| **3** | **snap** | Desktop apps while Guix packaging cost is too high |
| **4** | **podman** | Isolation, CI images, portable services |
| **5** | **Nix** | Escape hatch (hard packages e.g. some .NET); second pure-functional PM |

Language tools (**uv**, NuGet, Cargo, …) sit *inside* projects and outrank all of the above for app libraries.

### Decision tree

```
Need a library for an app I'm writing?
  → language package manager (uv / nuget / cargo / …) inside a project

Need a CLI or runtime on my PATH for many projects?
  → edit profile-full.scm then: guix package -m guix/manifests/profile-full.scm
  → last resort: scripts/installing-daily-use-apps.sh (guix install …)
  → if Guix lacks it or build cost is absurd → apt (host) or nix profile
  → if GUI vendor app → snap/flatpak temporarily

Is it kernel, firmware, display, audio, printer, bluetooth?
  → apt (stage 1 host)

Will it fight the host (pinned distros, dirty SDKs)?
  → podman (or distrobox)

Guix System later (no apt/snap)?
  → Guix services + podman + optional Nix
```

## Guix first — practical rules

- Prefer **stow**, **uv**, **python**, editors via Guix when substitutes exist.
- Use **manifests** under `guix/manifests/`.
- Source `~/.guix-profile` in every interactive shell (`stow-source/shell`).
- Rely on **`channels.scm`** (nonguix + community as needed) — see `guix/channels.scm`.
- Referent ecosystem: Emacs/Guix/Scheme educators such as **David Wilson** (System Crafters) for workflow patterns — not a mandatory channel URL, a cultural north star.
- `guix pull` is intentional (network + time).

### How to install Guix packages (Qimono preference order)

| Priority | Method | When |
|----------|--------|------|
| **1 — preferred** | `guix package -m guix/manifests/profile-full.scm` | Daily profile; reproducible full set |
| **2 — last resort** | `scripts/installing-daily-use-apps.sh` (`guix install …`) | Recover one missing app; avoid editing Scheme mid-crisis |

**Why prefer `profile-full.scm`:** one source of truth, one generation, no “forgot to list stow”.  
**Why `guix install` is last resort:** easy to drift from the manifest; profile and git diverge.

### Critical: `guix package -m` replaces the profile

`guix package -m some.scm` installs **exactly** the packages in that manifest.  
It does **not** merge with what you already had. Using a slim `quantum-host-rust.scm` alone can remove `emacs`, `uv`, `stow`, etc.

| Pattern | Command |
|---------|---------|
| Full intended set (**preferred**) | `guix package -m guix/manifests/profile-full.scm` |
| Additive emergency | `./scripts/installing-daily-use-apps.sh desktop` |
| Roll back | `guix package --roll-back` |

Lesson learned 2026-08-03: rust-only `-m` wiped prior profile; restored via `profile-full.scm`.

## apt second — host only

- Kernel, Mesa, firmware, `podman` if host-integrated, Microsoft `dotnet`/`code` already present.
- Do **not** apt-install Qiskit/PennyLane stacks.

## snap third

- Migration target: Guix browsers (Firefox, Epiphany, Chromium via channels) when effort allows.
- Current machine may still have snap browsers; experiment is P4 in the task plan.

## podman fourth

- Rootless preferred; Quadlet/user systemd for auto-start (see [teach-inits-shepherd.md](./teach-inits-shepherd.md)).

## Nix fifth — why add it

- Some stacks (historically **.NET** on Guix) are painful; Nixpkgs may unblock **quantum-host** experiments.
- On Guix System later, Nix remains a useful *other* functional PM; apt/snap will not.
- Install path (later): multi-user Nix or `guix install nix` patterns — document before enabling.

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| Treating ranking as religion | Document exceptions |
| apt + guix same binary fighting PATH | one source of truth |
| `pip install --user` globals | `uv tool` / project venv |
| snap python toolchains | Guix python + uv |
| docker daemon for local dev | podman |
| Copying `/gnu/store` across CPU arch | rebuild via manifests |

## Python policy (summary)

```
guix install python uv
# project:
uv python pin 3.12
uv add qiskit pennylane qdk jupyterlab …
```

Host `/usr/bin/python3` may be **3.14** — fine for OS scripts; scientific stacks use Guix/uv-managed 3.11/3.12.
