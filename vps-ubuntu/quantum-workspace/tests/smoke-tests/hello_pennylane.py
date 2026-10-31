#!/usr/bin/env python3
"""Minimal PennyLane Bell-pair smoke test."""

import pennylane as qml


def main() -> None:
    dev = qml.device("default.qubit", wires=2)

    @qml.qnode(dev)
    def circuit():
        qml.Hadamard(0)
        qml.CNOT([0, 1])
        return qml.probs(wires=[0, 1])

    probs = circuit()
    print("pennylane OK", probs.tolist() if hasattr(probs, "tolist") else list(probs))


if __name__ == "__main__":
    main()
