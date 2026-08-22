# Local LLM stack — Ollama + Gemma (fleet standard)

Decision recorded: **2026-08-21**. Before this file existed the fleet had a
knowledge gap: Ollama was known to be installed on some machines, but no model
choice, sizing rationale, or install procedure was written anywhere. This
document is the single source of truth. Do not rely on memory — update this
file instead.

## Fleet standard

| Item | Value |
|------|-------|
| Runtime | [Ollama](https://ollama.com) (official installer; systemd service `ollama.service`, enabled at boot) |
| Model | **`gemma4:e2b`** — Google Gemma 4 "Effective 2B" edge variant |
| Why e2b | Tiniest Gemma 4; runs offline with zero API cost; ~2.5–3 GiB resident RAM fits even the 6.5 GiB Yoga; multimodal (text + image), 128K context |
| Installer | `llm/install-ollama-stack.sh` (shared by all Linux packs) |
| Smoke test | `llm/hello-llm.sh` or `install-ollama-stack.sh --smoke` |

Background report: [`llm/gemma4-report.md`](../gemma4-report.md).

## Gemma 4 variants vs fleet machines

Download sizes are Ollama registry values; RAM figures are runtime estimates
(measured values marked). Update after measuring on real hardware.

| Tag | Download | Resident RAM | Yoga (6.5 G) | mini-pc (14.5 G) | hp-pro (30 G) |
|-----|----------|--------------|--------------|------------------|--------|
| `gemma4:e2b` | 7.2 GB | ~6.7 GB incl. KV cache (mostly file-backed)¹ | solo² | OK | **OK** |
| `gemma4:e4b` | 9.6 GB | ~4–5 GiB effective + KV | no | OK | **OK** |
| `gemma4:12b` | 7.6 GB* | ~8+ GiB | no | OK | **OK** |
| `gemma4:26b` MoE | 18 GB | ~20 GiB weights | no | no | tight |
| `gemma4:31b` | 20 GB | ~18 GiB | no | no | tight |

> 2026-08-22 correction: the hp-pro column originally assumed a small-RAM
> laptop ("tight/no"). Live capture (`ubuntu-hp-pro/MACHINE.md`) shows an
> i7-1255U with **30 GiB RAM + 24 GiB swap** — the roomiest fleet node.
> Fleet standard model stays `gemma4:e2b` (chosen 2026-08-22 for parity);
> e4b/12b are validated upgrades here when needed.

\* 12b ships smaller download than e4b but far larger resident footprint.

E-models use per-layer embeddings: 5.1 B / 8 B total parameters but only
2.3 B / 4.5 B *effective* active per token, which trims compute and some
memory — but the full weight set still lives in page cache while loaded.

¹ `ollama ps` SIZE on the Yoga, default 4096 context.
² See measured findings below: e2b runs fine on the Yoga **with Chrome
closed**; with Chrome open the loader was OOM-killed in practice.

## Usage

```bash
ollama run gemma4:e2b        # interactive chat (loads model into RAM)
ollama stop gemma4:e2b       # unload immediately; frees RAM
                             # (auto-unloads ~5 min after last use otherwise)
```

## Harness: `gemma.py` (2026-08-21)

Raw `ollama run` is the low-level path. The fleet-standard way to *use* the
model is the deterministic harness in this folder
(**Agent = Model + Harness**: gemma only writes text; the harness does all
control flow). Built after `gemma-4-prompts.txt` showed e2b failing agentic
tool loops (hallucinated `pennylane.jl`, "please provide a task" drift)
while passing direct Q&A.

```bash
./gemma.py doctor                              # probe whole stack
./gemma.py ask "how do I put a qubit in superposition?"
./gemma.py search "bell state"                 # retrieval preview, no model call
./gemma.py verify snippet.py                   # quality-gate any python file
./gemma.py eval                                # regression suite, 7 prompts
./gemma.py chat                                # REPL with auto-compaction
```

Architecture (all stdlib-only):

| Piece | Role |
|-------|------|
| `skills/*.md` | curated knowledge packs (quantum/python/qiskit basics) |
| `corpus/` | scraped docs: Qiskit course ch.1 + guides + PennyLane intro (`tools/scrape_docs.py`, run online) |
| `index/corpus.db` | SQLite FTS5 keyword index, 224 KiB — zero model RAM; rebuild with `./gemma.py index` |
| `modelfile/GemmaQ` | system prompt injected per-call via API (no derived model copy) |
| `.venv/` | uv venv with qiskit + qiskit-aer used by the verification gate |
| `mcp/gemma-tools-server.py` | stdio MCP server (docs_search / run_snippet / get_skill) for big-model clients like opencode — **not** for e2b itself |
| `eval/prompts.txt` | regression suite incl. the two originally-failing prompts |

Generation is schema-constrained (`format={"answer","code"}`, temperature
0.2, seed 7); generated snippets execute in `.venv` and failures feed the
traceback back for at most 2 repairs.

Measured first run (Yoga, CPU): 7/7 eval PASS; latency 34–53 s per prompt;
3 of 4 code answers executed clean (VERIFIED ✓).

Known minor issues:

- Rare JSON-escape leak when the model double-wraps its JSON (eval prompt 7);
  answer still parses as PASS but displays raw. Cosmetic.
- RAM guard refuses to start under 3 GiB free, but continues if the model is
  already resident (`/api/ps`) — keepalive keeps it loaded ~5 min.
- Offline rebuilds are impossible by design: refresh corpus while online
  (`tools/scrape_docs.py && ./gemma.py index`), then go offline.

## Usage

```bash
ollama run gemma4:e2b        # interactive chat (loads model into RAM)
ollama stop gemma4:e2b       # unload immediately; frees RAM
                             # (auto-unloads ~5 min after last use otherwise)
```

CPU-only expectation on fleet AMD laptops: roughly 8–15 tokens/s class.
No CUDA in fleet; ROCm iGPU support is not assumed.

## Measured on `ubuntu-len-yog-AMD64` (2026-08-21)

Ryzen 5 8640HS, 6.3 GiB RAM, Ollama 0.32.15, `gemma4:e2b`:

| Condition | Result |
|-----------|--------|
| ~4.7 GiB available (Chrome closed) | **PASS** — marker reply exact; eval 25.9–29.3 tok/s CPU; load ≈ 19 s |
| ~1.6–3 GiB available (Chrome open) | **FAIL** — kernel OOM killer killed the loader mid-load (`ollama.service: Failed with result 'oom-kill'`); systemd auto-restarts the service, no damage |

Lessons:

- The 3 GiB preflight warning in `install-ollama-stack.sh` is the real
  threshold — respect it on 6–8 GiB machines.
- Close browsers/heavy apps *before* loading; loading is the peak-memory
  moment (weights repack buffer was ~876 MiB on top of mmap'd tensors).
- This box's Radeon 760M is visible to Ollama via Vulkan but dropped by
  default (`dropping integrated GPU`). Experiment flag for later:
  `OLLAMA_IGPU_ENABLE=1` (not yet validated in the fleet — record results
  here if you try it).

## Install on any fleet machine

```bash
cd ~/source/repos/qimono-repos/dotfiles/llm
./install-ollama-stack.sh --dry-run   # see what it would do
./install-ollama-stack.sh             # graceful: skips anything already present
./install-ollama-stack.sh --smoke     # ... and prove it works afterwards
```

The installer probes before acting (mini-pc `status.sh` style):

- `ollama` binary present? → skip install
- `ollama.service` active/enabled? → skip enable
- model already pulled? → skip pull
- preflight: warns under 3 GiB available RAM, refuses to pull under 10 G disk

## Machine wiring

| Pack | Integration |
|------|-------------|
| `ubuntu-mini-pc` | LLM probe section in `scripts/status.sh` ("is it already here") |
| `windows11` | `install-ollama.ps1` installs runtime and pulls `gemma4:e2b` |
| `ubuntu-hp-pro`, `ubuntu-len-yog-AMD64` | use the shared script directly |

## Thinking mode note

Gemma 4 supports configurable thinking via `<|think|>` in the system prompt;
Ollama handles the chat template. For multi-turn chats, do not feed previous
thought blocks back as history.
