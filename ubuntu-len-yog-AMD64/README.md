# ubuntu-len-yog-AMD64

Machine-specific dotfiles and bootstrap for the **Lenovo Yoga 7 2-in-1 14AHP9 (AMD64)**.

| Field | Value |
|-------|-------|
| Host | `qimono-localhost` |
| Hardware | Lenovo Yoga 7 2-in-1 14AHP9 (SKU 83DK) |
| CPU | AMD Ryzen 5 8640HS (6c/12t, Phoenix) |
| GPU | AMD Radeon 760M (HawkPoint1, iGPU) |
| Arch | `x86_64` / `amd64` |
| OS | Ubuntu 26.04 LTS (Resolute Raccoon) |
| Sibling | Lenovo Yoga Snapdragon → use a separate pack (`ubuntu-len-yog-ARM64` or similar) |

This pack is **not** the generic VPS/ubuntu tree under `dotfiles/ubuntu/`. That folder is shared/server-oriented. This one is the laptop AMD64 profile.

## Package manager ranking (authoritative)

| Rank | Manager | Role |
|------|---------|------|
| **1** | **GNU Guix** | Primary userland: CLI tools, Python runtime, editors, reproducibility |
| **2** | **apt** | Host OS only: kernel, firmware, drivers, desktop, system daemons |
| **3** | **snap** | Desktop apps when Guix/apt lack a good build (browsers already snap) |
| **4** | **podman** | Isolated/reproducible workloads, heavy SDKs, CI-like sandboxes |

Avoid installing the same tool via two managers. Prefer Guix for anything user-scoped.

## Layout

```
ubuntu-len-yog-AMD64/
  README.md                 # this file
  MACHINE.md                # hardware + software inventory snapshot
  docs/
    package-managers.md     # policy detail + decision tree
    quantum-computing.md    # Qiskit / PennyLane / Q# stack
    stow.md                 # how to apply packages
  guix/
    channels.scm            # optional nonguix + default
    manifests/
      base.scm              # stow, uv, python, core CLI
      quantum-host.scm      # host-side deps useful for quantum work
  scripts/
    bootstrap.sh            # idempotent: guix packages + stow + uv + quantum
    install-guix-python-uv.sh
    install-quantum-python.sh
    install-qsharp.sh
    stow-apply.sh
  stow/
    shell/                  # ~/.zshrc.d + local hooks
    guix-env/               # ~/.config/guix + profile sourcing helper
    quantum/                # ~/.config/quantum defaults
  examples/quantum-hello/   # smoke tests for the three frameworks
```

## Quick start

```bash
# From this directory
./scripts/bootstrap.sh

# Or stepwise
./scripts/install-guix-python-uv.sh
./scripts/stow-apply.sh
./scripts/install-quantum-python.sh
./scripts/install-qsharp.sh
```

After bootstrap, open a new shell (or `source ~/.zshrc`) so Guix profile + `uv` are on `PATH`.

## Stow convention

```bash
# Target: $HOME
# Source packages live under ./stow/<package>
stow -d stow -t "$HOME" -v shell guix-env quantum
```

Use `./scripts/stow-apply.sh` so the same flags stay consistent across machines.

## Quantum frameworks (target)

| Framework | Language | Install path |
|-----------|----------|--------------|
| **Qiskit** | Python | `uv` project / tool env (Guix Python as base when possible) |
| **PennyLane** | Python | same `uv` env as Qiskit (shared scientific stack) |
| **Q#** | Q# / .NET | system `dotnet` (apt/Microsoft) + `qsharp` Python package / Azure Quantum |

See [docs/quantum-computing.md](./docs/quantum-computing.md).

## Related trees

- `dotfiles/ubuntu/` — generic Ubuntu / VPS notes and apt lists
- `dotfiles/gnu-guix/` — Guix system recipes, channels, package lists
- `dotfiles/zsh/` — shared zsh snippets (may diverge from live `~/.zshrc`)
- `$HOME/AGENTS.md` — agent-facing machine insights (not project-scoped)
