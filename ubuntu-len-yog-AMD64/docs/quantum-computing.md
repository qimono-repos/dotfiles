# Quantum computing stack — Qiskit · PennyLane · Q#

Target environment for this AMD64 Yoga and other Linux hosts following the same policy.

## Goals

- One **Python** scientific environment for **Qiskit** and **PennyLane** (shared numpy/scipy ecosystem).  
- **Q#** via **.NET SDK** (already on host) plus the Microsoft **`qdk`** Python package (`from qdk import qsharp`; legacy `qsharp` PyPI name is deprecated).  
- Reproducible installs: Guix for runtimes, **uv** for Python deps, manifests for Guix profile.

## Resource reality (this laptop)

- **6.5 GiB RAM** — local state-vector simulation of large qubit counts will thrash.  
- Start with ≤12–16 qubits for dense simulation unless using approximate methods.  
- Prefer Aer/Lightning with low memory settings; offload to cloud QPUs for scale.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Host: Ubuntu 26.04 (apt: kernel, mesa, dotnet, podman)  │
├─────────────────────────────────────────────────────────┤
│ Guix profile: python, uv, stow, jupyter, editors, …     │
│   Notebook UI on 127.0.0.1:5005 (stowed config)         │
├─────────────────────────────────────────────────────────┤
│ uv project: ~/source/repos/.../quantum-workspace        │
│   qiskit, qiskit-aer, pennylane, pennylane-lightning,   │
│   matplotlib, ipykernel, qdk (Q#)                       │
├─────────────────────────────────────────────────────────┤
│ .NET 10 SDK: Q# projects / Azure Quantum templates      │
└─────────────────────────────────────────────────────────┘
```

## Install order

1. Guix base (`python`, `uv`, `stow`, build tools) — `scripts/install-guix-python-uv.sh`  
2. Stow shell hooks — `scripts/stow-apply.sh`  
3. Guix Jupyter + stowed config — `scripts/install-jupyter.sh`  
4. Python quantum env — `scripts/install-quantum-python.sh`  
5. Q# / .NET check + sample — `scripts/install-qsharp.sh`  

## Qiskit

```bash
# inside the uv project created by install-quantum-python.sh
uv add qiskit qiskit-aer
# optional visualization / IBM runtime
uv add matplotlib pylatexenc qiskit-ibm-runtime
```

Smoke:

```python
from qiskit import QuantumCircuit
from qiskit.primitives import StatevectorSampler

qc = QuantumCircuit(2)
qc.h(0)
qc.cx(0, 1)
qc.measure_all()
print(StatevectorSampler().run([qc], shots=128).result()[0].data.meas.get_counts())
```

## PennyLane

```bash
uv add pennylane
# CPU-friendly default device; lightning is optional/fast if wheels exist
uv add pennylane-lightning
```

Smoke:

```python
import pennylane as qml

dev = qml.device("default.qubit", wires=2)

@qml.qnode(dev)
def circuit():
    qml.Hadamard(0)
    qml.CNOT([0, 1])
    return qml.probs(wires=[0, 1])

print(circuit())
```

## Q#

### .NET side

Host already has **.NET SDK 10**. Classic full QDK workloads evolved toward **Azure Quantum Development Kit** and the **`qsharp`** package.

```bash
dotnet --list-sdks
# project templates may vary by year; prefer official Azure Quantum docs
dotnet new install Microsoft.Quantum.ProjectTemplates  # if still published
```

### Python interop (`qdk`)

```bash
uv add qdk
# legacy: uv add qsharp  # deprecated alias
```

```python
from qdk import qsharp

qsharp.eval("""
operation Bell() : (Result, Result) {
    use (a, b) = (Qubit(), Qubit());
    H(a);
    CNOT(a, b);
    let r = (M(a), M(b));
    Reset(a); Reset(b);
    r
}
""")
print(qsharp.run("Bell()", shots=16))
```

## Cloud backends (recommended on this machine)

| Provider | Typical client package | Notes |
|----------|------------------------|-------|
| IBM Quantum | `qiskit-ibm-runtime` | API token in env / `~/.qiskit` |
| Azure Quantum | Azure CLI + workspace config | ties to Q# / Python |
| AWS Braket | `amazon-braket-sdk` / PennyLane plugin | optional |

Store secrets outside git (`~/.secrets/`, env files not stowed with tokens).

## Jupyter (localhost — reduce Colab dependency)

Infrastructure goal: **local** notebooks work without Google Colab. Colab may remain a convenient online option; this session’s responsibility is successful local tooling + browsers.

**Jupyter Notebook is Guix-global** (`guix install jupyter` / package name
`jupyter`). Guix ships classic Notebook (not JupyterLab). Quantum frameworks
stay in the **uv** project; register that venv as a kernelspec so notebooks can
import Qiskit/PennyLane.

Durable settings are **split** (public policy vs secrets):

```text
~/.jupyter/jupyter_notebook_config.py     ← Stow / git (ip, port, loads secrets)
  ← stow-source/jupyter/.jupyter/jupyter_notebook_config.py

~/.secrets/jupyter_auth.py                ← machine-local only (password HASH)
  created by:  scripts/setup-jupyter-auth.sh
```

Stowed non-secret policy:

```python
c.ServerApp.ip = "127.0.0.1"
c.ServerApp.port = 5005
c.ServerApp.port_retries = 0
# then optionally exec ~/.secrets/jupyter_auth.py
```

**Machine policy (this Yoga):** Jupyter is a **login-time user service** —
enabled so it starts whenever your graphical/login session’s
`default.target` comes up. That matches a quantum + mobile-frontend daily box
where notebooks should already be listening on `127.0.0.1:5005`.

It is still a **user service** (not a boot-as-root system daemon). With
`Linger=no` (default), it starts after you log in, not at the greeter.

### First-time setup

```bash
cd ~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64
./scripts/install-jupyter.sh           # guix + stow + enable --now
./scripts/setup-jupyter-auth.sh        # password hash → ~/.secrets/jupyter_auth.py
./scripts/install-quantum-python.sh    # Qiskit/PennyLane + ipykernel in uv project

# Optional: make the quantum venv selectable in the notebook UI
cd "${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"
uv run python -m ipykernel install --user --name=quantum --display-name="Python (quantum)"
```

### Auth (token vs password) and secret management

Default Jupyter uses a **random token** (shown in `journalctl` / `jupyter notebook list`).
For daily use, prefer a **password**: only a **hash** is stored on disk; keep the
passphrase in a password manager.

| Location | Contents | In git? |
|----------|----------|---------|
| Password manager | Login passphrase | No |
| `~/.secrets/jupyter_auth.py` | Password **hash** + `token=""` | No |
| Stow `jupyter_notebook_config.py` | Bind address/port only | Yes |
| `journalctl` | May leak old tokens — prefer password + empty token | — |

```bash
./scripts/setup-jupyter-auth.sh
# → ~/.secrets/ (0700) / jupyter_auth.py (0600)
# → optional restart of qimono-jupyter.service
```

Then browse **`http://127.0.0.1:5005`** and log in with the password (no token).

Do **not** put plaintext passwords or live tokens in `stow-source/`. Example
template only: `docs/examples/jupyter_auth.py.example`.

### Daily use

```bash
systemctl --user status qimono-jupyter.service
# After setup-jupyter-auth: open http://127.0.0.1:5005 (password)
# If still on token auth (no secrets file yet):
journalctl --user -u qimono-jupyter.service -n 30 --no-pager

# Temporary stop (e.g. free RAM for a heavy build):
systemctl --user stop qimono-jupyter.service
# Start again without re-enable:
systemctl --user start qimono-jupyter.service

# Opt out of auto-start at login (policy change):
systemctl --user disable qimono-jupyter.service
```

The unit runs `~/.guix-profile/bin/jupyter notebook`. Address and port come
from the stowed config (not CLI flags). If port 5005 is busy, the server fails
rather than silently rebinding.

Foreground one-shot (same config; rarely needed when the unit is enabled):

```bash
~/source/repos/qimono-repos/dotfiles/ubuntu-len-yog-AMD64/scripts/run-jupyter-lab.sh
```

The script honours `QIMONO_QUANTUM_HOME` for the working directory.

**RAM:** the idle Notebook process is modest; open kernels + browser tabs are
what hurt on ~6.5 GiB. Stop kernels you are not using.

### Browsers (Guix-preferred experiment)

| Browser | Goal |
|---------|------|
| Firefox | Guix package (may need channels / locale care) |
| GNOME Web (Epiphany) | Guix |
| Chromium | Guix + often **nonguix** / community channel |

This host already had Ubuntu Firefox and snap Epiphany/Vivaldi; migrating browsers to Guix is a **P4** task (see `tasks-priority-plan.md`) — uninstall snaps only when Guix browsers are verified.

**RAM:** Jupyter + browser + IDE on 6.5 GiB is tight; close spare apps.

Prefer VS Code notebooks only if that process is already open and you need to save RAM.

## Podman escape hatch

When host Python/Guix wheels fail:

```bash
podman run --rm -it -v "$PWD":/work -w /work python:3.12-bookworm bash
# then install uv + packages inside container
```

## Verification

```bash
./tests/smoke-tests/run-all.sh
```

Expect three OK lines (Qiskit, PennyLane, Q#). Failures should print the framework name and traceback.

Math/diagram stack for notebooks and docs (braket, Greek, formulas): **LaTeX** in Markdown/Jupyter; architecture in **Mermaid**; heavier diagrams in **draw.io** (local).
