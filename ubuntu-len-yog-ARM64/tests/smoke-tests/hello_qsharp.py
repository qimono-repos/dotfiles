#!/usr/bin/env python3
"""Minimal Q# via Microsoft QDK Python package (qdk)."""

from qdk import qsharp


def main() -> None:
    qsharp.eval(
        """
        operation BellSample() : Result {
            use q = Qubit();
            H(q);
            let r = M(q);
            Reset(q);
            r
        }
        """
    )
    outcomes = qsharp.run("BellSample()", shots=8)
    print("qsharp/qdk OK", outcomes)


if __name__ == "__main__":
    main()
