# Jupyter Notebook (ubuntu-hp-pro)

Fleet policy matches **Yoga** (`ubuntu-len-yog-AMD64`): Guix `jupyter`, local
bind **127.0.0.1:5005**, password auth via machine-local secrets, systemd **user**
unit at login.

## Day-one (once per machine)

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-hp-pro
./scripts/install-jupyter.sh      # guix (if needed) + stow + enable --now
./scripts/setup-jupyter-auth.sh   # password → ~/.secrets/jupyter_auth.py
```

Open **http://127.0.0.1:5005** and log in with the password (no token in URL).

## Layout

| Path | Role |
|------|------|
| `stow-source/jupyter/.jupyter/jupyter_notebook_config.py` | Bind/port; loads secrets |
| `~/.secrets/jupyter_auth.py` | Password **hash** only (never commit) |
| `~/.config/systemd/user/qimono-jupyter.service` | `jupyter notebook` user unit |
| `~/source/repos/qimono-repos/quantum-workspace` | Unit `WorkingDirectory` |

## Ops

```bash
systemctl --user status qimono-jupyter.service
journalctl --user -u qimono-jupyter.service -n 30 --no-pager
systemctl --user restart qimono-jupyter.service
```

Sibling reference: `ubuntu-len-yog-AMD64/docs/quantum-computing.md` (Jupyter section).
