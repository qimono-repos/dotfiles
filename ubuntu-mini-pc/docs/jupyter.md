# Jupyter Notebook (ubuntu-mini-pc)

Fleet ceremony matches HP / Yoga: Guix `jupyter`, bind **127.0.0.1:5005**,
password hash in `~/.secrets`, systemd **user** unit at login.

## Day-one (once)

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-mini-pc
./scripts/install-jupyter.sh      # stow + enable --now (jupyter already in profile)
./scripts/setup-jupyter-auth.sh   # password → ~/.secrets/jupyter_auth.py
```

Open **http://127.0.0.1:5005** and log in (no token in the URL).

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

The unit runs `~/.guix-profile/bin/jupyter notebook` **without**
`LD_LIBRARY_PATH` (that would leak into `!ls` and break Ubuntu coreutils).
NumPy / Aer wheels get Guix `libz` / `libstdc++` from the venv
`sitecustomize.py` installed by `install-quantum-python.sh`.

It is a **user** service (not root, not at the greeter). With default
`Linger=no` it starts after you log in.

## Auth

| Location | Contents | In git? |
|----------|----------|---------|
| Password manager | Login passphrase | No |
| `~/.secrets/jupyter_auth.py` | Hash + `token=""` | No |
| Stow config | ip / port only | Yes |

Example template only: `docs/examples/jupyter_auth.py.example`.
