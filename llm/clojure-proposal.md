# Proposal: port the gemma harness to Clojure (Babashka)

**Status:** PROPOSED — not started · **Date:** 2026-08-21
**Sibling implementation:** [`gemma.py`](../gemma.py) (working, eval 7/7)
**Scope:** this folder only; both implementations share `corpus/`,
`index/corpus.db`, `skills/`, `.venv/`, `modelfile/GemmaQ`, `eval/`.

## Why port at all

The Python harness works. This port is a **learning-driven exercise** with a
real payoff: the pipeline (`retrieve → assemble → generate → verify`) is a
pure-data flow that suits Lisp idioms better than Python, and every stage is
individually testable at the REPL.

## Runtime decision: Babashka (not JVM Clojure)

The instinct when asking was *Babashka + REPL workflow* — and that is exactly
the right call. Stock JVM Clojure (~300–500 MB RSS, slow cold start, deps
tooling) is a bad roommate on 6.5 GiB machines that also host e2b.
**Babashka** is a single static binary: ~60–80 MB RSS, millisecond startup,
runs `.clj` scripts like Python runs `.py`, built-in http-client/cheshire/
process, and its own nREPL for editor-integrated REPL work.

## Prerequisites — current state probed on `qimono-localhost` (2026-08-21)

| Tool | State | Notes |
|------|-------|-------|
| `bb` / `babashka` | **absent** | must be installed (M0) |
| `clojure` / `clj` CLI | **absent** | not needed for the bb path |
| `java` | present via Guix profile | irrelevant to Babashka; do not rely on it fleet-wide |
| sqlite FTS5 | proven working (index/corpus.db) | access from bb is milestone M1's spike |

**Install plan (M0)** — official static-binary installer, user-local so no
sudo and no system pollution:

```bash
curl -sLO https://raw.githubusercontent.com/babashka/babashka/master/install
bash install --dir ~/.local/bin     # then: bb --version
```

Fleet rule: one vendored binary per machine, installed by an idempotent
`tools/install-bb.sh` in the same probe/skip style as
`install-ollama-stack.sh`; later add a `bb` line to `gemma.py doctor`.

## Effort estimate

| Aspect | Estimate |
|--------|----------|
| Total effort | **1–2 evenings** (M0–M3); polish + parity M4/M5 → call it a weekend |
| Size | ~400–600 lines of Clojure |
| Difficulty | **low–medium** — nothing conceptually new; one packaging wrinkle |
| Highest risk | FTS5 access from Babashka → spike it FIRST (M1); fallback is the xerial JDBC jar vendored into the repo |

## Component mapping

| gemma.py | gemma.clj (Babashka) |
|----------|----------------------|
| urllib POST `/api/chat` | `babashka.http-client` (post + JSON body) |
| json.loads/dumps | cheshire (built-in) |
| sqlite3 FTS5 query | next.jdbc + xerial jar, or bb sqlite pod (M1 decides) |
| subprocess verify gate | `babashka.process` (shell/sh + timeout) |
| argparse subcommands | small `case` dispatch or clojure.tools.cli |
| chat history compaction | immutable vector + `take-last` — prettier than the Python version |
| TUTORIAL string | identical text, printed verbatim |

Retry loop becomes a `reduce` over attempts; RAM guard a predicate; the whole
ask-pipeline a `(-> question retrieve assemble generate verify)` thread.

## Milestones

- **M0 — toolchain:** install-bb.sh + `bb --version` smoke; doctor gains a bb row.
- **M1 — FTS5 spike:** query index/corpus.db from bb; decide pod vs JDBC. Kill criterion if hopeless: keep search in Python, call it via process — still fine.
- **M2 — offline commands:** `search`, `show`, `index`, `help`, `doctor` (no model calls needed to test).
- **M3 — the core:** `ask` + schema-constrained generation + verify gate + repair loop.
- **M4 — `chat`:** history, think-strip, compaction threshold logic.
- **M5 — `eval` + parity:** regression suite must reproduce the Python run's result (**7/7 PASS**) before either is allowed to drift.

## Acceptance criteria

1. `bb gemma.clj ask "how do I put a qbit in superposition?"` → VERIFIED ✓, fully offline.
2. `eval` parity with gemma.py (7/7).
3. RSS while resident ≤ 100 MB measured alongside a loaded e2b.

## Non-goals

- No rewrite of scraper/indexer internals (Python tools stay authoritative).
- No MCP changes (server already language-agnostic over stdio).
- No UI beyond the existing terminal surface.

## Open questions

- Pod vs JDBC for SQLite (M1 output).
- Whether mini-pc / hp-pro packs should adopt bb too once proven here.
