# stow package: jupyter (ARM64)

**JupyterLab via uv** in the `quantum-workspace` — on this Snapdragon host the
monolithic Guix `jupyter` package is NOT available (no aarch64 build), so
JupyterLab is a normal uv dependency instead. See
`docs/jupyter-arm64.md`.

## Layout

| Path | Managed by | Purpose |
|------|------------|---------|
| `.jupyter/jupyter_notebook_config.py` → `~/.jupyter/…` | **Stow / git** | ip, port, loads secrets |
| `~/.secrets/jupyter_auth.py` | **Local only** | password **hash**, token policy |
| `.config/systemd/user/qimono-jupyter.service` | Stow | user service unit (`uv run jupyter lab`) |

## Prerequisites

```bash
./scripts/install-guix-python-uv.sh    # guix: uv + python + stow
./scripts/install-quantum-python.sh    # uv: add jupyterlab + qiskit + pennylane
./scripts/stow-apply.sh                # stow this package into $HOME
```

## Apply + enable (machine policy)

```bash
stow -d stow-source -t "$HOME" -v jupyter
# (or: ./scripts/stow-apply.sh)
systemctl --user daemon-reload
systemctl --user enable --now qimono-jupyter.service
```

Then open `http://127.0.0.1:5005`.

## Auth / secret management

Do **not** put passwords or tokens in the stow tree. Password hash + token live
in `~/.secrets/jupyter_auth.py` (chmod 600), loaded by the stowed config.

## Config (fixed local bind)

```python
c.ServerApp.ip = "127.0.0.1"
c.ServerApp.port = 5005
c.ServerApp.port_retries = 0
```

## Ops

```bash
systemctl --user status qimono-jupyter.service
journalctl --user -u qimono-jupyter.service -n 30 --no-pager
./scripts/run-jupyter-lab.sh   # foreground one-shot
```
