# ubuntu-len-yog-ARM64

Machine pack for the **Lenovo Yoga Slim 7 14Q8X9 (Snapdragon / ARM64)** — Qimono
infrastructure for the **Ying-Yang Project (2026/2027)**.

| Field | Value |
|-------|-------|
| Host | `qi-yoga-ubu-rr-lts` |
| Hardware | Lenovo Yoga Slim 7 14Q8X9 (SKU 83ED) |
| CPU | Qualcomm Snapdragon X Elite (Oryon), 12c |
| Arch | `aarch64` / `arm64` |
| OS | Ubuntu 26.04 LTS (Resolute Raccoon) |
| Sibling | Lenovo Yoga AMD64 → separate pack (`ubuntu-len-yog-AMD64`) |

This is the **ARM64 sibling** of the AMD Yoga pack. It mirrors the same
stow + Guix-first layout but avoids any x86_64-only blobs.

Feedback tracking: [feedback-plan.md](./feedback-plan.md) ·
[tasks-priority-plan.md](./tasks-priority-plan.md)

## Package manager ranking (aspirational)

| Rank | Manager | Role when it wins |
|------|---------|-------------------|
| **1** | **GNU Guix** | Preferred userland: CLI, Python, editors, manifests, channels |
| **2** | **apt** | Host OS: kernel, firmware, desktop, system daemons |
| **3** | **snap** | Desktop apps when Guix effort is too high (migrate when ready) |
| **4** | **podman** | Isolation, CI-like images, portable services |
| **5** | **Nix** | Escape hatch |

## Layout

```
ubuntu-len-yog-ARM64/
  README.md
  MACHINE.md
  QA/
  docs/
    jupyter-arm64.md
  guix/
    channels.scm
    manifests/
      base.scm
      profile-full.scm
  scripts/
    bootstrap.sh
    install-guix-binary.sh     # sudo: unpack store + build users (aarch64)
    finish-guix-binary.sh      # sudo: /usr/local/bin/guix + keys + daemon
    install-host-sysctl.sh     # sudo: Guix userns (AppArmor)
    install-guix-python-uv.sh  # guix: stow, python, uv, editors …
    install-quantum-python.sh  # uv: qiskit, pennylane, qdk, jupyterlab
    run-jupyter-lab.sh         # one-shot JupyterLab on 127.0.0.1:5005
    stow-apply.sh
    machine-discovery.sh
  stow-source/          # NOT named "stow" (clearer CLI)
    shell/
    guix-env/
    quantum/
    jupyter/
    nvim/
```

## Quick start

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-ARM64

# 0) GNU Guix binary (aarch64) — two sudo steps:
sudo ./scripts/install-guix-binary.sh     # unpack store + build users
sudo ./scripts/finish-guix-binary.sh      # /usr/local/bin/guix + keys + daemon

# 1) Host sysctl (once): Guix userns for sandboxes
sudo ./scripts/install-host-sysctl.sh

# 2) Guix base toolchain (stow, python, uv, editors, zlib)
./scripts/install-guix-python-uv.sh

# 3) Quantum workspace: uv + qiskit + pennylane + qdk + JupyterLab
./scripts/install-quantum-python.sh

# 4) Stow dotfiles into $HOME
./scripts/stow-apply.sh

# 5) Enable JupyterLab on 127.0.0.1:5005 (user service, no sudo)
systemctl --user enable --now qimono-jupyter.service
```

Then open a new shell (or `source ~/.zshrc`) so Guix + `uv` are on `PATH`.
Verify with:
```bash
cd "${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"
uv run python tests/smoke-tests/run-all.sh     # Qiskit · PennyLane · Q#
```

## Stow convention

Source tree is **`stow-source/`**; apply with:

```bash
./scripts/stow-apply.sh
# = stow -d stow-source -t "$HOME" -v --restow shell guix-env quantum nvim jupyter
```

Why we stow **snippets** (`.zshrc.d`) instead of a full `.zshrc`:
[docs/stow.md](./docs/stow.md) (shared with the AMD pack).

## Host AppArmor trap (do this first, survives reboot)

```bash
./scripts/install-host-sysctl.sh
sysctl kernel.apparmor_restrict_unprivileged_userns   # must be 0
```

Wired into `./scripts/bootstrap.sh` step 0.

## ARM64 traps (learned 2026-08-27)

1. **`/usr/local/bin/guix` is NOT in the aarch64 tarball.** The Guix binary
   lives at `/var/guix/profiles/per-user/root/current-guix/bin/guix`, and no
   systemd unit or substitute keys ship with it. `finish-guix-binary.sh`
   creates the symlink, authorizes keys, and installs the daemon unit.
2. **`guix jupyter` has no aarch64 build** → use JupyterLab from uv
   ([docs/jupyter-arm64.md](./docs/jupyter-arm64.md)).
3. **Compiled wheels need `libz.so.1`** (scipy-openblas/numpy). Do **NOT** add
   `/lib/aarch64-linux-gnu` to `LD_LIBRARY_PATH` — it segfaults the Guix
   python. Instead add `zlib` to the manifest and export
   `LD_LIBRARY_PATH=$GUIX_PROFILE/lib` (see `20-uv-python.zsh`).

## Quantum frameworks

| Framework | Language | Install path |
|-----------|----------|--------------|
| **Qiskit** | Python | uv project (`quantum-workspace`) |
| **PennyLane** | Python | same uv env |
| **Q# / qdk** | Python | same uv env (`qdk` package) |
| **JupyterLab** | — | **uv** (the Guix `jupyter` pkg is not aarch64-supported) on `127.0.0.1:5005` |

> On ARM64 the monolithic Guix `jupyter` package cannot be installed, so
> JupyterLab comes from the uv workspace. See [docs/jupyter-arm64.md](./docs/jupyter-arm64.md).

## Local LLM (offline)

Fleet standard: **Ollama + `gemma4:e2b`**. See the shared tool:

```bash
~/source/repos/qimono-repos/dotfiles/llm/install-ollama-stack.sh --dry-run
```

Full sizing table + measurements: [`../llm/docs/local-llm.md`](../llm/docs/local-llm.md)
