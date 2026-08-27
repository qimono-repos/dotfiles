#!/usr/bin/env python3
"""Minimal Qiskit Bell-pair smoke test."""

from qiskit import QuantumCircuit
from qiskit.primitives import StatevectorSampler


def main() -> None:
    qc = QuantumCircuit(2)
    qc.h(0)
    qc.cx(0, 1)
    qc.measure_all()

    result = StatevectorSampler().run([qc], shots=128).result()
    counts = result[0].data.meas.get_counts()
    print("qiskit OK", dict(counts))


if __name__ == "__main__":
    main()
