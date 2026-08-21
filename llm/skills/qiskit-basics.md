# Qiskit basics (offline skill pack)

## Canonical superposition example (Qiskit ≥ 1.0)

```python
from qiskit import QuantumCircuit, transpile
from qiskit_aer import AerSimulator

qc = QuantumCircuit(1, 1)      # 1 qubit, 1 classical bit
qc.h(0)                        # Hadamard: |0> -> (|0>+|1>)/sqrt(2)
qc.measure(0, 0)               # measure qubit 0 into classical bit 0

sim = AerSimulator()
job = sim.run(transpile(qc, sim), shots=1024)
counts = job.result().get_counts(qc)
print(counts)                  # ~ {'0': 512, '1': 512}
```

## Circuit construction essentials

```python
qc = QuantumCircuit(n_qubits[, n_clbits])
qc.h(0)            # Hadamard
qc.x(1)            # Pauli-X (NOT)
qc.z(0)            # phase flip
qc.cx(0, 1)        # CNOT: control=0, target=1
qc.measure([0, 1], [0, 1])          # measure all
qc.measure_all()                    # adds a barrier + measures everything
```

## Simulation patterns

Statevector (pure math, no shots):

```python
from qiskit.quantum_info import Statevector
sv = Statevector.from_instruction(qc)     # qc WITHOUT measure ops
print(sv.probabilities_dict())            # {'00': 0.5, '11': 0.5}
```

Shot-based (sampling):

```python
from qiskit_aer import AerSimulator
sim = AerSimulator()
job = sim.run(transpile(qc, sim), shots=1024)
print(job.result().get_counts())
```

Rules of thumb:

- Remove `measure` before Statevector analysis; keep it for counts runs.
- `transpile(qc, backend)` adapts the circuit to the backend's basis gates.
- `get_counts()` needs the original `qc` object passed in.

## Entanglement in three lines

```python
qc = QuantumCircuit(2, 2)
qc.h(0); qc.cx(0, 1)       # Bell state (|00>+|11>)/sqrt(2)
qc.measure([0, 1], [0, 1])
```

Expected counts: only '00' and '11', never '01' or '10'.

## Drawing and inspection

- `print(qc.draw())` — ASCII diagram, offline-safe.
- `qc.depth()`, `qc.num_qubits`, `qc.count_ops()` — quick introspection.
