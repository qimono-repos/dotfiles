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
│ Guix profile: python, uv, stow, git, editors, …         │
├─────────────────────────────────────────────────────────┤
│ uv project: ~/source/repos/.../quantum-workspace        │
│   qiskit, qiskit-aer, pennylane, pennylane-lightning,   │
│   matplotlib, jupyter, qdk (Q#)                         │
├─────────────────────────────────────────────────────────┤
│ .NET 10 SDK: Q# projects / Azure Quantum templates      │
└─────────────────────────────────────────────────────────┘
```

## Install order

1. Guix base (`python`, `uv`, `stow`, build tools) — `scripts/install-guix-python-uv.sh`  
2. Stow shell hooks — `scripts/stow-apply.sh`  
3. Python quantum env — `scripts/install-quantum-python.sh`  
4. Q# / .NET check + sample — `scripts/install-qsharp.sh`  

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

```bash
cd "${QIMONO_QUANTUM_HOME:-$HOME/source/repos/qimono-repos/quantum-workspace}"
uv add jupyterlab ipykernel
uv run jupyter lab --no-browser
# then open http://127.0.0.1:8888 in Firefox / GNOME Web / Chromium
```

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
