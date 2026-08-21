# Terminal workflow — ask Gemma, run quantum snippets

Verbatim flow for testing LLM-generated Qiskit / PennyLane snippets:

```bash
cd ~/source/repos/qimono-repos/dotfiles/llm
./gemma.py ask "..."        # snippet
uv sync                     # installs once; no-op afterwards
./run python                # >>>
>>> from qiskit import QuantumCircuit   ✓
```

## Notes

- `uv sync` is idempotent: first run downloads everything into `.venv/`;
  every later run just audits (~30 ms) and installs nothing.
  Re-run it only after editing `pyproject.toml`.
- Packages live in `.venv/`, so bare `python3` cannot see them —
  always enter the environment via `./run python`.
- `./run` = `uv run` plus the Guix `LD_LIBRARY_PATH` fix (libz /
  libstdc++) that wheels like NumPy and Aer need on Guix machines.
- `python3` alone still opens the Guix system Python (3.11) without
  any project packages — by policy, on every machine.
