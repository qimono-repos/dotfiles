#!/usr/bin/env python3
"""gemma.py — deterministic harness around gemma4:e2b (Agent = Model + Harness).

The model only produces text; this script decides everything else:
retrieval, prompt assembly, schema-constrained generation, snippet
verification and retries. Stdlib-only; talks to the local Ollama HTTP API.

QUICK START (copy-paste):
  ./gemma.py doctor                              health check of the whole stack
  ./gemma.py search "superposition"              peek at what gemma will read
  ./gemma.py ask "How do I put a qubit in superposition?"
  ./gemma.py ask "show a Bell state example" --no-verify
  ./gemma.py verify my_snippet.py                quality-gate any python file
  ./gemma.py chat                                offline REPL with compaction
  ./gemma.py eval                                run eval/prompts.txt regression
  ./gemma.py index                               rebuild keyword index

Typical offline session:
  1. close Chrome/heavy apps (e2b needs ~4.7 GiB free to load)
  2. ./gemma.py doctor        # everything OK except maybe RAM
  3. ./gemma.py ask "..."

Beginner tutorial: ./gemma.py help
"""

import argparse
import json
import os
import re
import sqlite3
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
DB = HERE / "index" / "corpus.db"
SYSTEM_FILE = HERE / "modelfile" / "GemmaQ"
EVAL_FILE = HERE / "eval" / "prompts.txt"
HISTORY = HERE / "eval" / "history.jsonl"
VENV_PY = HERE / ".venv" / "bin" / "python"

MODEL = os.environ.get("GEMMA_MODEL", "gemma4:e2b")
HOST = os.environ.get("OLLAMA_HOST", "http://127.0.0.1:11434").rstrip("/")
if not HOST.startswith("http"):
    HOST = "http://" + HOST
MIN_RAM_MIB = int(os.environ.get("GEMMA_MIN_RAM_MIB", "3072"))

CTX_BUDGET_CHARS = 12000
CHAT_MAX_CHARS = 16000
COMPACT_THRESHOLD = 22000
SCHEMA = {"type": "object",
          "properties": {"answer": {"type": "string"},
                         "code": {"type": "string"}},
          "required": ["answer", "code"]}
STOPWORDS = {"the", "a", "an", "is", "are", "how", "do", "i", "in", "with",
             "to", "of", "what", "and", "for", "on", "it", "this", "that",
             "can", "you", "me", "my", "use", "using"}

TUTORIAL = """\
GEMMA-Q QUICK TUTORIAL  (offline harness around gemma4:e2b)

WHAT AM I LOOKING AT?
  gemma.py = librarian + prompt-fitter + API client + test runner
  wrapped around the tiny local model. The model writes text;
  this script does everything else (retrieval, retries, checks).

STEP 1 - check your machine is ready
  ./gemma.py doctor
    green table: index, skills, venv, ollama, model pulled, free RAM
    "available RAM ... WAIT" means: close Chrome/heavy apps, re-run

STEP 2 - ask your first question (works fully offline)
  ./gemma.py ask "how do I put a qbit in superposition?"
    retrieves doc chunks -> asks gemma -> executes any generated
    snippet in .venv -> prints answer + code + VERIFIED badge

MORE TOOLS
  ./gemma.py search "bell state"     peek at what gemma would read
  ./gemma.py verify my_snippet.py    quality-gate any python file
  ./gemma.py chat                    interactive REPL (/exit /compact /reset)
  ./gemma.py eval                    regression suite (eval/prompts.txt)
  ./gemma.py index                   rebuild index after editing skills/corpus

RAM TIP  e2b needs ~4.7 GiB free to LOAD; stays resident ~5 min after
         each call. Free it anytime with: ollama stop gemma4:e2b

Full CLI reference: ./gemma.py --help
"""


def log(msg):
    print(msg, file=sys.stderr)


# ---------- ollama io ----------

def mem_avail_mib():
    for line in Path("/proc/meminfo").read_text().splitlines():
        if line.startswith("MemAvailable:"):
            return int(line.split()[1]) // 1024
    return -1


def model_resident():
    """True if MODEL is currently loaded in Ollama (keepalive window)."""
    try:
        with urllib.request.urlopen(HOST + "/api/ps", timeout=3) as r:
            models = json.loads(r.read()).get("models", [])
        return any(MODEL in (m.get("name"), m.get("model"))
                   for m in models)
    except Exception:
        return False


def ram_guard(force=False):
    avail = mem_avail_mib()
    if force or avail < 0 or avail >= MIN_RAM_MIB:
        return True
    if model_resident():
        log(f"NOTE  available RAM {avail} MiB but {MODEL} is already "
            f"resident — continuing")
        return True
    log(f"WAIT  available RAM {avail} MiB < {MIN_RAM_MIB} MiB — "
        f"close Chrome/heavy apps or bypass with --force")
    return False


def strip_think(text):
    text = re.sub(r"<think>.*?</think>", "", text, flags=re.S)
    return re.sub(r"<think>.*\Z", "", text, flags=re.S).strip()


def ollama_chat(messages, schema=None, timeout=300):
    payload = {"model": MODEL, "messages": messages, "stream": False,
               "options": {"temperature": 0.2, "seed": 7, "num_ctx": 4096}}
    if schema is not None:
        payload["format"] = schema
    req = urllib.request.Request(
        HOST + "/api/chat", data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            data = json.loads(r.read().decode())
    except urllib.error.URLError as e:
        raise RuntimeError(f"cannot reach Ollama at {HOST} ({e}); "
                           f"is 'ollama.service' running?") from None
    return strip_think(data.get("message", {}).get("content", ""))


def parse_answer(raw):
    raw = raw.strip()
    try:
        obj = json.loads(raw)
        if isinstance(obj, dict) and "answer" in obj:
            code = obj.get("code") or ""
            if isinstance(code, list):          # some models emit arrays
                code = "\n".join(str(x) for x in code)
            return str(obj.get("answer", "")).strip(), code.strip()
    except json.JSONDecodeError:
        pass
    m = re.search(r"\{.*\}", raw, flags=re.S)
    if m:
        try:
            obj = json.loads(m.group(0))
            return str(obj.get("answer", raw)).strip(), \
                str(obj.get("code", "")).strip()
        except json.JSONDecodeError:
            pass
    return raw, ""


# ---------- retrieval ----------

def search_chunks(query, k=5):
    terms = [w for w in re.findall(r"[a-z0-9_]+", query.lower())
             if len(w) > 1 and w not in STOPWORDS]
    if not terms:
        return []
    where = " OR ".join(f'"{t}"' for t in terms[:12])
    con = sqlite3.connect(DB)
    try:
        rows = con.execute(
            "SELECT source, title, body, bm25(chunks) AS rank "
            "FROM chunks WHERE chunks MATCH ? ORDER BY rank LIMIT ?",
            (where, k * 4)).fetchall()
    finally:
        con.close()
    per_source, out = {}, []
    for src, title, body, rank in rows:
        if per_source.get(src, 0) >= 2:
            continue
        per_source[src] = per_source.get(src, 0) + 1
        out.append({"source": src, "title": title, "body": body,
                    "score": round(-rank, 2)})
        if len(out) == k:
            break
    return out


def assemble_context(query):
    chunks = search_chunks(query)
    if not chunks:
        return ""
    parts, budget = [], CTX_BUDGET_CHARS
    for c in chunks:
        if len(c["body"]) + 200 > budget:
            continue
        parts.append(f'[{c["source"]} · {c["title"]}]\n{c["body"]}')
        budget -= len(c["body"]) + 200
    ctx = "\n\n---\n\n".join(parts)
    best = chunks[0]
    recap = f'[RECAP — most relevant source: {best["source"]}]'
    return ctx + "\n\n---\n\n" + recap


def system_prompt():
    return SYSTEM_FILE.read_text(encoding="utf-8")


# ---------- verification gate ----------

def run_snippet(code, timeout=90):
    if not VENV_PY.exists():
        return False, (f"venv missing ({VENV_PY}). Create it with:\n"
                       f"  ~/.guix-profile/bin/uv venv {HERE}/.venv && "
                       f"~/.guix-profile/bin/uv pip install --python "
                       f"{VENV_PY} qiskit qiskit-aer")
    with tempfile.TemporaryDirectory() as td:
        script = Path(td) / "snippet.py"
        script.write_text(code, encoding="utf-8")
        try:
            p = subprocess.run([str(VENV_PY), str(script)], cwd=td,
                               capture_output=True, text=True, timeout=timeout)
        except subprocess.TimeoutExpired:
            return False, f"timeout after {timeout}s"
        tail = ((p.stdout or "") + (p.stderr or "")).strip()[-1200:]
        return p.returncode == 0, tail or "(no output)"


# ---------- commands ----------

def cmd_ask(q, no_verify=False, retries=2, force=False):
    if not ram_guard(force):
        return 1
    t0 = time.time()
    ctx = assemble_context(q)
    user_msg = f"CONTEXT:\n{ctx}\n\nQUESTION: {q}" if ctx else q
    messages = [{"role": "system", "content": system_prompt()},
                {"role": "user", "content": user_msg}]

    answer = code = ""
    verified, output_for_hist = True, ""
    for attempt in range(retries + 1):
        raw = ollama_chat(messages, schema=SCHEMA)
        answer, code = parse_answer(raw)
        if no_verify or not code:
            break
        verified, output = run_snippet(code)
        if verified:
            break
        if attempt < retries:
            log(f"repair {attempt + 1}/{retries}: snippet failed, "
                f"feeding traceback back")
            messages.append({"role": "assistant", "content": raw})
            messages.append({
                "role": "user",
                "content": "Your code failed with:\n```\n"
                           + output[-800:] + "\n```\nReturn corrected JSON "
                           "with the same schema. Keep the same goal."})
        else:
            output_for_hist = output

    dt = time.time() - t0
    print("=" * 60)
    print(answer or "(empty answer)")
    if code:
        print("-" * 60)
        print(code)
        badge = "VERIFIED ✓" if verified else f"VERIFY FAILED ✗"
        print("-" * 60)
        print(badge + ("" if verified else f"\n{output_for_hist}"))
    print("=" * 60)
    log(f"[{MODEL}] {dt:.1f}s · context {'yes' if ctx else 'none'} · "
        f"verified={'n/a' if (no_verify or not code) else verified}")

    HISTORY.parent.mkdir(parents=True, exist_ok=True)
    with HISTORY.open("a") as f:
        f.write(json.dumps({"ts": time.strftime("%Y-%m-%dT%H:%M:%S"),
                            "model": MODEL, "q": q,
                            "pass": bool(answer) and (no_verify or not code
                                                      or verified),
                            "latency_s": round(dt, 1)}) + "\n")
    return 0


def cmd_chat(force=False):
    if not ram_guard(force):
        return 1
    print(f"gemma chat — model {MODEL}. /exit quits, /compact forces "
          f"summary, /reset clears history.")
    history, summary = [], None
    while True:
        try:
            q = input("you> ").strip()
        except (EOFError, KeyboardInterrupt):
            break
        if not q:
            continue
        if q in ("/exit", "/quit"):
            break
        if q == "/reset":
            history, summary = [], None
            print("(history cleared)")
            continue
        if q != "/compact":
            history.append({"role": "user", "content": q})

        total = sum(len(m["content"]) for m in history)
        if (q == "/compact" or total > COMPACT_THRESHOLD) and history:
            old = history[:-2] if len(history) > 2 else history
            blob = "\n".join(f'{m["role"]}: {strip_think(m["content"])}'
                             for m in old)[:6000]
            summary = ollama_chat([
                {"role": "system", "content":
                 "Summarize the conversation in at most 150 words, keeping "
                 "every technical fact, library name and decision."},
                {"role": "user", "content": blob}])
            history = history[-2:]
            print("(compacted)", file=sys.stderr)

        prefix = [{"role": "system", "content": system_prompt()}]
        if summary:
            prefix.append({"role": "system", "content":
                           f"Conversation so far (summary): {summary}"})
        while sum(len(m["content"]) for m in history) > CHAT_MAX_CHARS \
                and len(history) > 2:
            history = history[1:]
        reply = ollama_chat(prefix + history, timeout=300)
        clean = strip_think(reply)
        print(clean or "(empty reply)")
        history.append({"role": "assistant", "content": clean})
    return 0


def cmd_search(q, k=5):
    chunks = search_chunks(q, k=k)
    if not chunks:
        print("no matches")
        return 1
    for i, c in enumerate(chunks, 1):
        preview = " ".join(c["body"].split())[:100]
        print(f"{i:>2}. [{c['score']:>6}] {c['source']} :: {c['title']}")
        print(f"      {preview}…")
    return 0


def cmd_show(n):
    con = sqlite3.connect(DB)
    rows = con.execute("SELECT rowid FROM chunks").fetchall()
    if n < 1 or n > len(rows):
        print(f"rowid out of range (1..{len(rows)})")
        return 1
    rid = rows[n - 1][0]
    row = con.execute("SELECT source, title, body FROM chunks "
                      "WHERE rowid=?", (rid,)).fetchone()
    con.close()
    print(f"# {row[0]} :: {row[1]}\n\n{row[2]}")
    return 0


def cmd_verify(path):
    code = Path(path).read_text(encoding="utf-8")
    ok, out = run_snippet(code)
    print(("PASS ✓" if ok else "FAIL ✗") + "\n" + out)
    return 0 if ok else 1


def cmd_eval(strict=False, no_verify=False, force=False):
    prompts = [ln.strip() for ln in EVAL_FILE.read_text().splitlines()
               if ln.strip() and not ln.startswith("#")]
    results = []
    for q in prompts:
        print(f"\n### {q}", file=sys.stderr)
        cmd_ask(q, no_verify=no_verify, force=force)
        last = HISTORY.exists() and \
            json.loads(HISTORY.read_text().splitlines()[-1])
        ok = bool(last) and last.get("q") == q and last.get("pass")
        results.append((q, ok))
    print("\n" + "=" * 60)
    width = max(len(q) for q, _ in results)
    for q, ok in results:
        print(f"{'PASS' if ok else 'FAIL':<5} {q:<{width}}")
    npass = sum(ok for _, ok in results)
    print(f"{npass}/{len(results)} passed")
    if strict and npass < len(results):
        return 1
    return 0


def cmd_index():
    r = subprocess.run([sys.executable, str(HERE / "tools" / "build_index.py")])
    return r.returncode


def probe(name, ok, detail=""):
    mark = "OK  " if ok else "MISS"
    print(f"  {name:<34} {mark}  {detail}")
    return ok


def cmd_doctor():
    print(f"=== gemma harness on {os.uname().nodename} — model: {MODEL} ===\n")

    def sh(cmd, timeout=25):
        try:
            return subprocess.run(cmd, capture_output=True, text=True,
                                  timeout=timeout)
        except Exception:
            return None

    probe("index db (FTS5)", DB.exists(),
          f"{DB}" if DB.exists() else "run: ./gemma.py index")
    n_chunks = 0
    if DB.exists():
        try:
            con = sqlite3.connect(DB)
            n_chunks = con.execute("SELECT count(*) FROM chunks").fetchone()[0]
            con.close()
            probe("indexed chunks", n_chunks > 0, f"{n_chunks}")
        except sqlite3.Error as e:
            probe("indexed chunks", False, str(e))
    skills = sorted((HERE / "skills").glob("*.md"))
    corpus_files = sorted((HERE / "corpus").rglob("*.md"))
    probe("skill packs", len(skills) >= 3,
          ", ".join(s.name for s in skills))
    probe("corpus docs", len(corpus_files) >= 5, f"{len(corpus_files)} files")
    probe("venv python", VENV_PY.exists(), str(VENV_PY))
    if VENV_PY.exists():
        q = sh([str(VENV_PY), "-c", "import qiskit, qiskit_aer"])
        probe("qiskit importable in venv", q and q.returncode == 0,
              (q.stdout or "").strip() or "")
    try:
        with urllib.request.urlopen(HOST + "/api/version", timeout=5) as r:
            ver = json.loads(r.read()).get("version", "?")
        probe("ollama reachable", True, f"{HOST} v{ver}")
        with urllib.request.urlopen(HOST + "/api/tags", timeout=5) as r:
            tags = [m["name"] for m in json.loads(r.read()).get("models", [])]
        probe(f"model pulled ({MODEL})", MODEL in tags,
              "pulled" if MODEL in tags else f"have: {', '.join(tags) or '-'}")
    except Exception as e:
        detail = str(e)
        probe("ollama reachable", False, f"{HOST} ({detail})")

    avail = mem_avail_mib()
    ram_ok = avail >= MIN_RAM_MIB
    probe("available RAM",
          ram_ok, f"{avail} MiB (need ≥{MIN_RAM_MIB})" +
                  ("" if ram_ok else " — close heavy apps"))
    net = sh(["curl", "-sI", "--max-time", "4", "https://ollama.com"], 8)
    online = bool(net and net.returncode == 0)
    probe("network", True, "ONLINE" if online else
          "OFFLINE (fine — that is the point)")
    return 0


# ---------- cli ----------

def main(argv=None):
    ap = argparse.ArgumentParser(
        prog="gemma.py",
        description="Deterministic offline harness around gemma4:e2b.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__.split("QUICK START", 1)[1].replace("QUICK START:", "",
                                                          1))
    sub = ap.add_subparsers(dest="cmd", required=False)
    sub.add_parser("help", help="show the quick tutorial")

    p_ask = sub.add_parser("ask", help="one-shot RAG question -> verified answer")
    p_ask.add_argument("question")
    p_ask.add_argument("--no-verify", action="store_true",
                       help="skip snippet execution gate")
    p_ask.add_argument("--force", action="store_true",
                       help="bypass RAM preflight guard")

    sub.add_parser("chat", help="interactive REPL with auto-compaction")

    p_s = sub.add_parser("search", help="show retrieved chunks (no model call)")
    p_s.add_argument("query")
    p_s.add_argument("-k", type=int, default=5)

    p_show = sub.add_parser("show", help="print full chunk N by rowid")
    p_show.add_argument("n", type=int)

    p_v = sub.add_parser("verify", help="quality-gate a python file")
    p_v.add_argument("file")

    p_e = sub.add_parser("eval", help="regression suite from eval/prompts.txt")
    p_e.add_argument("--strict", action="store_true",
                     help="nonzero exit on any FAIL")
    p_e.add_argument("--no-verify", action="store_true",
                     help="skip snippet execution gate")
    p_e.add_argument("--force", action="store_true")

    sub.add_parser("doctor", help="probe the whole stack (status-style)")
    sub.add_parser("index", help="rebuild FTS index from skills/ + corpus/")

    args = ap.parse_args(argv)
    if args.cmd is None or args.cmd == "help":
        print(TUTORIAL)
        return 0
    if args.cmd == "ask":
        return cmd_ask(args.question, no_verify=args.no_verify,
                       force=args.force)
    if args.cmd == "chat":
        return cmd_chat()
    if args.cmd == "search":
        return cmd_search(args.query, k=args.k)
    if args.cmd == "show":
        return cmd_show(args.n)
    if args.cmd == "verify":
        return cmd_verify(args.file)
    if args.cmd == "eval":
        return cmd_eval(strict=args.strict, no_verify=args.no_verify,
                        force=args.force)
    if args.cmd == "doctor":
        return cmd_doctor()
    if args.cmd == "index":
        return cmd_index()
    return 2


if __name__ == "__main__":
    sys.exit(main())
