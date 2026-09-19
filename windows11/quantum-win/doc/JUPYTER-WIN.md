# Jupyter / Lab — Windows 11 on Snapdragon X (offline-able, 127.0.0.1:5005)

Direct mirror of the ubuntu `qimono-jupyter.service` (systemd --user), which
runs classic Jupyter Notebook on **127.0.0.1:5005** — see
`ubuntu-hp-pro/stow-source/jupyter/` for the stowed source + its
`jupyter_notebook_config.py` (ip 127.0.0.1, port 5005, no token).

On Windows there is no systemd, so the same job is a **Scheduled Task**:

| ubuntu (systemd --user) | this machine (Scheduled Task) |
|---|---|
| `qimono-jupyter.service` | `qimono-jupyter-win` |
| runs at login (`WantedBy=default.target`) | runs at every logon (`AtLogOn`) |
| `jupyter notebook` via Guix profile | `uv run --extra lab jupyter lab` (uv, project-scoped) |
| port 5005, `127.0.0.1` only, no token | port 5005, `--ip=127.0.0.1`, `.token=''` |
| config from `~/.jupyter/` (stow) | flags passed directly on the uv run line |

## One-time registration (Git Bash / Ghostty, after `bootstrap-quantum-win-offline.ps1`)

```powershell
cd windows11\quantum-win
.\register-jupyter-startup-task.ps1     # registers the logon task
Start-ScheduledTask -TaskName qimono-jupyter-win
# browser at http://127.0.0.1:5005   (terminal-first: nothing auto-opens)
```

If you prefer a manual terminal session instead of the task:
`.\run-jupyter-lab.ps1` does the same uv run in the foreground.

## Offline contract

- **qiskit 2.5.2 + rustworkx 0.18.1** — vendored ARM64 wheels under `wheels/`,
  committed. uv **never** source-builds them (`no-build-package` in pyproject +
  `find-links = ["wheels"]`). A fresh `git clone` → `uv sync` works offline for
  the quantum core.
- **jupyterlab + ipykernel** — pure-Python, fetched once by uv on first sync,
  then served from the uv cache. They do NOT need Rust, so they are NOT
  vendored. If you need matplotlib too, add it to `[project.optional-dependencies]`.
- No GPU needed for terminal qiskit. (GPU acceleration is a separate follow-up;
  this machine does CPU simulations fine.)

## Ports in use

| port | job | runs on boot? |
|---|---|---|
| 5005 | JupyterLab (offline, localhost) | ✅ logon task `qimono-jupyter-win` |
