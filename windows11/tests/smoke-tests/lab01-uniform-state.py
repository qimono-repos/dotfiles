# Grover Lab 1 — uniform state (resume checkpoint)
# Usage (Ghostty / PowerShell, from quantum-workspace):
#   .\.venv\Scripts\python.exe tests\lab01-uniform-state.py
#
# Prediction BEFORE running: 3 qubits, H on all -> 2^3 = 8 strings,
# each probability 1/8 = 0.125, total = 1.0.

from qiskit import QuantumCircuit
from qiskit.quantum_info import Statevector

q = QuantumCircuit(3)
q.h([0, 1, 2])

probs = Statevector.from_instruction(q).probabilities_dict()

for key in sorted(probs):
    print(f"{key}  {probs[key]:.3f}")

assert len(probs) == 8, "expected 8 bit-strings"
assert all(abs(p - 0.125) < 1e-6 for p in probs.values()), "uniform 0.125 each"
assert abs(sum(probs.values()) - 1.0) < 1e-6, "probabilities sum to 1"
print("OK: 8 uniform strings at 0.125, sum 1.0 -> Grover uniform state reached")
