# VPS quantum workspace

Repository-managed Python 3.12 environment for Qiskit, Qiskit Aer, PennyLane,
QDK, NumPy, Matplotlib, and ipykernel. `uv.lock` pins the resolved dependency
graph. The global Guix profile supplies `uv`; scientific packages stay in this
workspace's ignored `.venv`.

```bash
uv run python --version
uv run python tests/smoke-tests/hello_qiskit.py
uv run python -m ipykernel install --user --name=quantum --display-name='Python (quantum)'
```

No Jupyter server is installed or exposed by this workspace. If one is added,
keep it loopback-bound and put access behind an authenticated channel.
