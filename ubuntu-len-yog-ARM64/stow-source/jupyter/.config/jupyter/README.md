# `~/.config/jupyter` (optional XDG tree)

Jupyter’s **default config directory** is still `~/.jupyter` (see
`jupyter --paths`). This pack’s durable notebook settings live there:

```text
~/.jupyter/jupyter_notebook_config.py
  ← stow-source/jupyter/.jupyter/jupyter_notebook_config.py
```

Use this `~/.config/jupyter` directory only if you later set
`JUPYTER_CONFIG_DIR=$HOME/.config/jupyter` or drop extra XDG-style files
here intentionally. Runtime data (kernels, lab workspaces) often still
uses `~/.local/share/jupyter` and `~/.jupyter`.
