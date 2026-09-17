# Grover Lab — Workspace anchor & Lesson 1 (uniform state)

**Verified 2026-09-17 in Ghostty (winghostty) on Snapdragon X (ARM64):**

```
qiskit 2.5.2 | rustworkx 0.18.1
```

## The one true anchor (never probe again)

- **venv python:** `C:\Users\qi\source\repos\qimono-repos\quantum-workspace\.venv\Scripts\python.exe`
- **runtime DLL fix for `qiskit/_accelerate`:**

```powershell
# ONE-TIME after any fresh uv sync — restores the llvm-mingw runtime DLL
# that pip's source-build does NOT bundle (ships without it by design).
$sp = "C:\Users\qi\source\repos\qimono-repos\quantum-workspace\.venv\Lib\site-packages"
Copy-Item "C:\Users\qi\Tools\llvm-mingw\bin\libunwind.dll" "$sp\qiskit\libunwind.dll" -Force
```

## Lesson 1 — the uniform state (the Grover starting point)

```powershell
cd C:\Users\qi\source\repos\qimono-repos\quantum-workspace
.\.venv\Scripts\python.exe
```

```python
from qiskit import QuantumCircuit
from qiskit.quantum_info import Statevector

q = QuantumCircuit(3)
q.h([0, 1, 2])

Statevector.from_instruction(q).probabilities_dict()
```

**Result (all 8 bit-strings, equal):**

```python
{'000': 0.125, '001': 0.125, '010': 0.125, '011': 0.125,
 '100': 0.125, '101': 0.125, '110': 0.125, '111': 0.125}
```

> Prediction-first habit: 3 qubits → 2³ = 8 strings, all equal → 1/8 = 0.125 each, sum 1.0.

## Next lesson pointer

Lesson 2 flips **exactly one amplitude** to negative (mark exactly one 3-bit
string with a −1). Where we stopped, that's the phase oracle — the "search"
part that makes Grover a search.

## Operability note

- This is the goal state reached on the **2026-09-17 (Halifax, ~02:10–02:45)**
  run. Full source-build resume record: `dotfiles/windows11/doc/BUILD-QUANTUM-WIN_ARM64.md`.
- Next resume needs **no downloads beyond LLVM runtime DLL copy above**; maybe
  `ipykernel` (already in workspace, tiny) if we spin a Jupyter kernel later.
