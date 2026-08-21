# Quantum computing basics (offline skill pack)

## Qubits and superposition

A classical bit is 0 or 1. A qubit is a quantum state |ψ⟩ = α|0⟩ + β|1⟩ where
α, β are complex amplitudes with |α|² + |β|² = 1. Measuring collapses the
qubit to |0⟩ with probability |α|² or |1⟩ with probability |β|².

A qubit in state |0⟩ becomes an equal superposition by applying the Hadamard
gate H: H|0⟩ = (|0⟩ + |1⟩)/√2, so measurement gives 50% "0", 50% "1".
H|1⟩ = (|0⟩ − |1⟩)/√2 (phase-flipped interference).

## Core single-qubit gates

| Gate | Matrix effect | Meaning |
|------|--------------|---------|
| X    | flips \|0⟩↔\|1⟩ | quantum NOT |
| Y    | flip + phase | combined bit/phase flip |
| Z    | \|1⟩ → −\|1⟩ | phase flip only |
| H    | creates superposition from basis states | Hadamard |
| S    | \|1⟩ → i\|1⟩ | quarter-turn phase |
| T    | \|1⟩ → e^{iπ/4}\|1⟩ | eighth-turn phase |

## Two-qubit gates

CNOT(control, target): if control is |1⟩, flip target. With H on the control,
CNOT creates entanglement — the Bell state (|00⟩ + |11⟩)/√2.

## Measurement

Measurement in the computational basis returns classical bits only.
Repeated shots (e.g. 1024) build a count histogram of outcomes.
Measuring one qubit of a Bell pair correlates both outcomes instantly.

## Entanglement vs superposition

Superposition: one system in many amplitudes at once.
Entanglement: joint state not writable as a product of single-qubit states;
correlations stronger than any classical shared randomness allow.

## Common student errors

- Thinking H gives a *random* bit directly: it gives deterministic amplitudes;
  randomness appears only at measurement.
- Forgetting that gates are unitary (reversible); measurement is the step
  that destroys information.
- Confusing |+⟩ = (|0⟩+|1⟩)/√2 with |0⟩ measured twice: measuring |+⟩ once
  collapses it; the second shot sees the collapsed value.
