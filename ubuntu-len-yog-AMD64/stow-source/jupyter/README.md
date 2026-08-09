# stow package: jupyter

Guix-global **Jupyter Notebook** (package `jupyter`) with a durable config and
an on-demand systemd user unit.

## Layout

| Stow path | → `$HOME` | Purpose |
|-----------|-----------|---------|
| `.jupyter/jupyter_notebook_config.py` | `~/.jupyter/jupyter_notebook_config.py` | `ServerApp.ip` / `port` |
| `.config/systemd/user/qimono-jupyter.service` | user unit | on-demand server |
| `.config/jupyter/README.md` | XDG note | Jupyter still defaults to `~/.jupyter` |

## Prerequisites

```bash
guix install jupyter
# or: ./scripts/install-jupyter.sh
source ~/.guix-profile/etc/profile
```

Guix does **not** currently ship JupyterLab as a first-class package; this pack
uses classic **Notebook** (`jupyter notebook`). Quantum libs stay in the uv
project (`quantum-workspace`); register that env as a kernel when needed.

## Apply

```bash
stow -d stow-source -t "$HOME" -v jupyter
# or: ./scripts/stow-apply.sh
systemctl --user daemon-reload
```

## Config (fixed local bind)

```python
c.ServerApp.ip = "127.0.0.1"
c.ServerApp.port = 5005
# (+ NotebookApp.* mirrors and port_retries = 0)
```

## Start / stop

```bash
systemctl --user start qimono-jupyter.service
journalctl --user -u qimono-jupyter.service -n 30 --no-pager
# http://127.0.0.1:5005/tree?token=...

systemctl --user stop qimono-jupyter.service
```

Foreground one-shot:

```bash
./scripts/run-jupyter-lab.sh
```
