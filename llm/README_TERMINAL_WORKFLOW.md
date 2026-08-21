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
  libstdc++) that wheels like NumPy and Aer need when Python/libs
  come from guix (Ubuntu GNOME + guix as package manager here).
- `python3` alone still opens the Guix system Python (3.11) without
  any project packages — by policy, on every machine.

## Offload Gemma (free ~5 GiB of RAM)

Gemma stays resident for ~5 min after each call (Ollama keepalive).
Unload it gracefully whenever you need the memory back:

```bash
ollama ps                  # is the model resident? (shows SIZE)
ollama stop gemma4:e2b     # graceful unload — no data loss
ollama ps                  # should print only the header now
```

- Nothing is deleted: weights stay on disk; the next `./gemma.py ask`
  reloads the model automatically (~30–60 s cold start).
- `./gemma.py doctor` shows free RAM before/after.

## Airplane mode (session-only)

Runtime switch via NetworkManager — no sudo on a desktop session,
identical on Debian, Ubuntu, Fedora, Arch, openSUSE (anywhere NM runs):

```bash
nmcli networking off       # ✈ offline NOW (all NM-managed interfaces down)
nmcli networking           # -> disabled
./gemma.py doctor          # network probe should report OFFLINE
nmcli networking on        # back online
```

- Session-scoped by design: NM reconnects everything on next boot.
- Safety net: some NM builds cache the flag in
  `/var/lib/NetworkManager/NetworkManager.state`; if a boot ever comes
  up offline, one `nmcli networking on` fixes it.
- Radios stay powered; Bluetooth untouched — silence it too with
  `bluetoothctl power off` (also resets at reboot).
- Ollama listens on `127.0.0.1` only, so offline mode never affects
  `./gemma.py` — that is the point of the whole setup.
