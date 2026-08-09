# stow package: jupyter

Guix-global **Jupyter Notebook** (package `jupyter`) with durable non-secret
config, machine-local password auth, and a **login-enabled** systemd **user**
service for this quantum / mobile-frontend machine.

## Layout

| Path | Managed by | Purpose |
|------|------------|---------|
| `stow-source/jupyter/.jupyter/jupyter_notebook_config.py` → `~/.jupyter/…` | **Stow / git** | ip, port, loads secrets |
| `~/.secrets/jupyter_auth.py` | **Local only** | password **hash**, token policy |
| `.config/systemd/user/qimono-jupyter.service` | Stow | user service unit |
| `docs/examples/jupyter_auth.py.example` | git (example only) | template for secrets file |

## Prerequisites

```bash
guix install jupyter
# or: ./scripts/install-jupyter.sh   # also enable --now
source ~/.guix-profile/etc/profile
```

## Apply + enable (machine policy)

```bash
stow -d stow-source -t "$HOME" -v jupyter
# or: ./scripts/stow-apply.sh
systemctl --user daemon-reload
systemctl --user enable --now qimono-jupyter.service
```

## Auth / secret management

**Do not** put passwords or tokens in the stow tree.

```bash
./scripts/setup-jupyter-auth.sh
# writes ~/.secrets/jupyter_auth.py (chmod 600)
# store the passphrase in a password manager
systemctl --user restart qimono-jupyter.service   # if script did not
```

Then open `http://127.0.0.1:5005` and log in with the **password** (no token).

The stowed config always sets bind/port, then **execs** the secrets file if it
exists:

```text
~/.jupyter/jupyter_notebook_config.py   (stow — public policy)
        │
        └── loads  ~/.secrets/jupyter_auth.py   (local — hash + token="")
```

| Store | What |
|-------|------|
| Password manager | The login passphrase |
| `~/.secrets/jupyter_auth.py` | Argon2 (etc.) **hash** only + `token=""` |
| Git / stow | Never secrets |

Optional: you can still use `jupyter notebook password` (writes
`~/.jupyter/jupyter_notebook_config.json`); prefer
`setup-jupyter-auth.sh` so the hash lives under `~/.secrets/` with the rest of
machine secrets.

## Config (fixed local bind)

```python
c.ServerApp.ip = "127.0.0.1"
c.ServerApp.port = 5005
# (+ NotebookApp.* mirrors and port_retries = 0)
```

## Ops

```bash
systemctl --user status qimono-jupyter.service
journalctl --user -u qimono-jupyter.service -n 30 --no-pager

systemctl --user stop qimono-jupyter.service     # temporary
systemctl --user disable qimono-jupyter.service  # no auto-start
```

Foreground one-shot:

```bash
./scripts/run-jupyter-lab.sh
```
