# Skill: local Gemma terminal workflow (Ollama + Qiskit)

> Origin: llm/README_TERMINAL_WORKFLOW.md + RAMageddon.md, stress-tested on
> qimono-localhost 2026-08-21 (qubit-in-superposition run, end to end).
> Goal: ask the local model for quantum snippets and RUN them — without
> ever OOM-ing the workstation.

## When to use this skill

Prompting the fleet's local LLM (`gemma4:e2b` via Ollama) for Qiskit /
PennyLane snippets and executing them, on any RAM-tight fleet node.

## The philosophy (why this exists)

Agent = Model + Harness. `llm/gemma.py` owns retrieval (FTS5 corpus index),
prompt assembly, schema-constrained generation, snippet verification, and
retries. The model only produces text. Trust `verified=True`, not vibes.

## Core workflow (proven sequence)

```bash
cd ~/source/repos/qimono-repos/dotfiles/llm
./gemma.py doctor                        # gate: index, venv, qiskit, ollama, RAM, net
./gemma.py ask "How do I put a qubit in superposition?"
./run python /tmp/snippet.py             # uv run + Guix LD_LIBRARY_PATH fix
ollama stop gemma4:e2b                   # MANDATORY cleanup (see law 4)
```

Measured end-to-end (Yoga, cold): 76 s question→answer, verified=True,
executed counts `{'0': 516, '1': 508}` over 1024 shots.

## The laws

1. **Enter Python only via `./run python`.** Packages live in `.venv/`;
   bare `python3` is the Guix system Python by policy. `./run` adds the
   Guix LD_LIBRARY_PATH fix (libz/libstdc++) wheels like NumPy/Aer need.
2. **Doctor first, always.** It checks index db, skill packs, corpus,
   venv+qiskit, ollama reachability, model pulled, RAM, network.
3. **Know the REAL memory math.** `ollama ps` SIZE for `gemma4:e2b` is
   **~6.8 GB** — larger than the Yoga's total RAM (6.5 GiB!). It only fits
   thanks to swap headroom plus iGPU offload (observed 79%/21% CPU/GPU on
   Radeon 760M). The docstring's "needs ~4.7 GiB free" is optimistic;
   doctor's 3072 MiB gate is MORE optimistic — both can pass while the
   loader still dies.
4. **Unload after every session**: `ollama stop gemma4:e2b`; confirm with
   empty `ollama ps`. Measured release: 6.8 GB back, ~4.0 Gi available.
   Weights stay on disk; next ask pays a ~60 s cold reload. Keepalive would
   otherwise hold the model ~5 min.
5. **Offline by design**: Ollama listens on 127.0.0.1 only; airplane mode
   (`nmcli networking off`, session-scoped) never breaks the workflow.

## Crash signature: OOM during model load (learned twice)

| Signal | Meaning |
|---|---|
| `http.client.RemoteDisconnected` ~20–25 s into an ask | ollama died mid-load |
| ollama PID changed afterward (PPID=1, boot-started, no logs dir) | crash+respawn, no server logs kept |
| `free -h` shows MORE available after the failure | victim was the loader itself |

Fix that made it work: **double the swap file** (4G→8G on `/swap.img`):

```bash
sudo swapoff /swap.img && sudo rm /swap.img && \
sudo fallocate -l 8G /swap.img && sudo chmod 600 /swap.img && \
sudo mkswap /swap.img && sudo swapon /swap.img
```

A swap FILE consumes free disk only — nothing else shrinks or moves;
persistence rides the existing fstab line. Cost here: 4 GB of disk,
per RAMageddon doctrine (RAM upgrades are off the table until H2 2027).

## Tool-session traps

- `pkill -f '<pattern>'` matches its OWN command line → kills your shell.
  Use bracket tricks (`'[.]firefox-real'`) or `pgrep -x`.
- Kill by exact name when possible; check BOTH wrapper and real binary
  names (Guix firefox runs as `.firefox-real`).
- After killing residents, re-check `free -h` before retrying a load.

## Fleet sizing (from RAMageddon.md)

| Variant | Effective params | Node |
|---|---|---|
| `gemma4:e2b` | ~2.3 B | Yoga (floor case, swap mandatory) |
| `gemma4:e4b` | ~4.5 B | mini-pc, ProBook |
| `gemma4:12b` | dense | mini-pc on demand |

Heavy reasoning belongs on the mini-pc (14.5 GiB); the Yoga stays the
terminal copilot node.
