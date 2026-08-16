# Quantum stack — this mini-PC

Three layers. Qiskit is **not** a Guix package (search is empty on this
channel set). The “global React” is the shared uv project.

```
Ubuntu 26.04 (apt: kernel, desktop, /usr/bin/python3 for the OS)
  └── Guix user profile: python, uv, jupyter, gcc-toolchain, zlib, …
        ├── Jupyter Notebook UI  →  127.0.0.1:5005  (user unit)
        └── uv project  ~/source/repos/qimono-repos/quantum-workspace
              qiskit, qiskit-aer, numpy, matplotlib, scipy, ipykernel
```

## Install order

1. `scripts/apply-profile.sh` — Guix `profile-full.scm`
2. `scripts/stow-apply.sh` — PATH + jupyter config/unit
3. `scripts/install-jupyter.sh` — enable `--now`
4. `scripts/setup-jupyter-auth.sh` — **human**, once
5. `scripts/install-quantum-python.sh` — Guix python + uv add
6. `scripts/status.sh`

## What stays out of Guix

| Thing | Why | Where it lives |
|-------|-----|----------------|
| Qiskit / Aer | not packaged | `quantum-workspace` |
| Project snippets | pedagogical, per-folder | `qu/qiskit/` (later venv) |

`qu/qiskit/.venv` is a **later** project env. It must use
`uv sync --python python3` after Guix python is on PATH, so it pulls wheels
from `~/.cache/uv` instead of inventing a CPython.

## Day-1 packages in the uv project

`qiskit`, `qiskit-aer`, `numpy`, `matplotlib`, `scipy`, `ipykernel`.

Deferred: PennyLane, `qdk` / Q#, IBM tokens.

## Native libs

Guix Python does not search `/usr/lib`. NumPy / Aer wheels still `dlopen`
`libz` and `libstdc++`. **Do not** put `$GUIX_PROFILE/lib` on
`LD_LIBRARY_PATH` in the interactive shell — Ubuntu `ls` then loads Guix
`libm` and dies (`GLIBC_2.43 not found`).

`install-quantum-python.sh` copies `scripts/sitecustomize-guix-native.py`
into the venv so notebooks and `uv run python` preload those sonames
without exporting the path. Same lesson as `qu/qiskit/env.sh`, scoped to
the interpreter that needs it.
