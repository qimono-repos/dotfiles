# Jupyter on ARM64 — Guix vs uv

**tldr:** the monolithic Guix package `jupyter` does **not** support
`aarch64-linux`. The AMD Yoga pack installs `guix jupyter` (classic Notebook).
On this Snapdragon (ARM64) pack we run **JupyterLab from the uv workspace**
instead — cleaner, cross-arch, and the modern UI.

## Why not `guix install jupyter`

```console
$ guix package -m base.scm
guix package: error: package jupyter@1.0.0 does not support aarch64-linux
```

The `jupyter` Guix package is built only for x86_64/… and refuses to install
on this host. The underlying jupyter-server components exist on aarch64, but
bundling the full Notebook UI from Guix is not viable here.

## What we do instead

- **uv project** `quantum-workspace` (created by `scripts/install-quantum-python.sh`)
  adds `jupyterlab` + `notebook` + `ipykernel` as normal Python deps.
- **One-shot:** `./scripts/run-jupyter-lab.sh` → `uv run jupyter lab` on
  `127.0.0.1:5005`.
- **Auto-start:** `stow-source/jupyter/.config/systemd/user/qimono-jupyter.service`
  runs `uv run jupyter lab --no-browser` with `WorkingDirectory=quantum-workspace`.

```bash
# after install-quantum-python.sh + stow-apply.sh
systemctl --user daemon-reload
systemctl --user enable --now qimono-jupyter.service
# open http://127.0.0.1:5005
```

## Port / bind

The stowed `~/.jupyter/jupyter_notebook_config.py` fixes `127.0.0.1:5005`
(`ServerApp.*` traits — JupyterLab honours `jupyter_server` config). Secrets
stay in `~/.secrets/jupyter_auth.py` (never stowed).

## Q#

Q# via the `qdk` Python package installs from uv (wheels supported on ARM64).
Classic Notebook-specific kernel config is not used; the `quantum` kernelspec
is registered ad hoc with `uv run python -m ipykernel install --user`.
