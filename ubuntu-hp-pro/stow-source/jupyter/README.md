# stow package: jupyter

Guix-global **Jupyter Notebook** (package `jupyter`) with durable non-secret
config, machine-local password auth, and a **login-enabled** systemd **user**
service. Same policy as `ubuntu-len-yog-AMD64`: **127.0.0.1:5005**.

## Layout

| Path | Managed by | Purpose |
|------|------------|---------|
| `stow-source/jupyter/.jupyter/jupyter_notebook_config.py` → `~/.jupyter/…` | **Stow / git** | ip, port, loads secrets |
| `~/.secrets/jupyter_auth.py` | **Local only** | password **hash**, token policy |
| `.config/systemd/user/qimono-jupyter.service` | Stow | user service unit |
| `docs/examples/jupyter_auth.py.example` | git (example only) | template for secrets file |

## One-time setup (this machine)

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-hp-pro

# 1) Guix package + stow config/unit + enable --now
./scripts/install-jupyter.sh

# 2) Password once → hash under ~/.secrets/ (never git)
./scripts/setup-jupyter-auth.sh
```

Then open **`http://127.0.0.1:5005`** and log in with the password (no token).

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

## Auth / secret management

**Do not** put passwords or tokens in the stow tree.

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
