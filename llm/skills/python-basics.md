# Python basics for quantum work (offline skill pack)

## Running snippets on this machine (fleet standard)

Preferred runtime is uv-managed project environments; never pip-install into
the OS python. The harness venv lives next to this repo:

```bash
~/source/repos/qimono-repos/dotfiles/llm/.venv/bin/python script.py
```

That venv has `qiskit` and `qiskit-aer` preinstalled. Guix provides base
python (`~/.guix-profile/bin/python3`) and `uv`.

## Minimal runnable script shape

```python
from qiskit import QuantumCircuit

qc = QuantumCircuit(1)   # one qubit, zero classical bits
qc.h(0)                  # Hadamard on qubit 0
print(qc.draw())         # ASCII circuit diagram
```

Scripts must print results to stdout; no GUI calls offline (no
plot_histogram display without a viewer — printing `counts` dicts instead).

## Installing libraries (when online)

```bash
uv venv .venv                     # create env
uv pip install --python .venv/bin/python qiskit qiskit-aer pennylane
```

pip equivalent inside an activated venv: `pip install qiskit`.

## Error patterns worth memorizing

| Message | Cause / fix |
|---------|-------------|
| ModuleNotFoundError: No module named 'qiskit' | wrong interpreter; use .venv/bin/python |
| ImportError: cannot import name 'Aer' from 'qiskit' | Aer lives in qiskit_aer since Qiskit 1.x: `from qiskit_aer import AerSimulator` |
| TypeError: 'QuantumCircuit' object is not subscriptable | use qc.data or qc.find_bit(); indexing circuits changed across versions |
| qiskit.exceptions.QiskitError: 'Counts' | call result.get_counts(circuit), not result[...] |

## Version-sensitive imports (Qiskit ≥ 1.0)

- `from qiskit import QuantumCircuit, transpile`
- Simulation: `from qiskit_aer import AerSimulator`
- Backend run: `sim = AerSimulator(); job = sim.run(transpiled, shots=1024)`
- Statevector math: `from qiskit.quantum_info import Statevector`

Avoid deprecated patterns: `qiskit.BasicAer`, `qiskit.execute`,
`IBMQ`/`qiskit.IBMQ` (now `qiskit_ibm_runtime`).
