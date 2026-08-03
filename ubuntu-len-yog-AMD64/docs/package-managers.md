# Package manager policy

## Ranking

1. **Guix** — default for user tooling and language runtimes we control  
2. **apt** — host OS, drivers, desktop session, things that must integrate with systemd/kernel  
3. **snap** — GUI apps and vendor channels when Guix/apt are worse  
4. **podman** — isolation, heavy/conflicting stacks, one-shot experiments  

### Decision tree

```
Need a library for an app I'm writing?
  → language package manager (uv / nuget / cargo / …) inside a project

Need a CLI or runtime on my PATH for many projects?
  → guix install <pkg>   (or guix package -m manifests/…)

Is it kernel, firmware, display, audio, printer, bluetooth?
  → apt

Is it a desktop app and Guix build is broken/missing?
  → snap (or flatpak if already used elsewhere)

Will it fight the host (old CUDA, pinned distros, CI images)?
  → podman run / distrobox
```

## Guix first — practical rules

- Install **stow**, **uv**, **python** via Guix before apt equivalents.
- Use Guix **manifests** under `guix/manifests/` for reproducible profile sets.
- Source `~/.guix-profile` in every interactive shell (stow `shell` package).
- Prefer `guix shell -m manifest.scm` for project-local pure environments when possible.
- Run `guix pull` intentionally (network + time); pin channels when you need bit-for-bit rebuilds.

## apt second — host only

Examples that stay on apt:

- `linux-generic`, firmware, Mesa  
- `podman`, `build-essential` when compiling against host libc is required  
- Microsoft `code`, `dotnet` packages already on this host  
- Desktop session packages  

Do **not** `apt install python3-qiskit` style stacks; use **uv**.

## snap third

Already used for Firefox, Discord, PyCharm, Obsidian, VLC, etc. Keep it for those. Avoid snaps for CLI developer tools if Guix has them (`ripgrep`, `fd`, `fzf` are already Guix).

## podman fourth

Use for:

- Full quantum notebook stacks with pinned CUDA/ROCm images (this laptop is AMD iGPU only — CPU/ROCm containers, not NVIDIA)  
- CI-parity Ubuntu LTS images  
- Services you do not want on the host (databases, mock QPU gateways)

Prefer rootless podman. Compose via `podman compose` when needed.

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| apt + guix same binary name fighting PATH | one source of truth |
| pip install --user for global tools | `uv tool install` or project venv |
| snap install python | Guix python + uv |
| docker (daemon) for local dev | podman |
| bloating root FS with many Guix generations | `guix package --delete-generations` + `guix gc` |

## Python policy (summary)

```
guix install python          # stable 3.11.x for scientific wheels
guix install uv              # or ensure uv on PATH
uv venv --python $(guix package -p ~/.guix-profile -I python | …)
# simpler: point uv at Guix python explicitly
uv python pin 3.11           # when uv-managed CPython is acceptable
uv add qiskit pennylane …    # project deps
```

Host `/usr/bin/python3` is **3.14** — fine for OS scripts, often **too new** for Qiskit/PennyLane wheels. Prefer Guix or uv-managed 3.11/3.12.
