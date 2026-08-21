#!/usr/bin/env python3
"""Minimal stdio MCP server exposing the gemma harness functions as tools.

Implements the MCP 2025-06-18 lifecycle subset (initialize, ping,
tools/list, tools/call) over JSON-RPC 2.0 with zero third-party deps.
Intended clients: opencode/big-pickle sessions or any future bigger local
model — NOT gemma4:e2b itself (tiny models drive tools unreliably; the
harness calls the same functions deterministically instead).

Wire test:
  printf '%s\n' \
    '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18"}}' \
    '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
    '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' \
    '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"qiskit_docs_search","arguments":{"query":"superposition","k":2}}}' \
    | ./mcp/gemma-tools-server.py

Register with an MCP client (stdio transport):
  command: <repo>/dotfiles/llm/mcp/gemma-tools-server.py
"""

import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(HERE))

from gemma import search_chunks, run_snippet  # noqa: E402

PROTOCOL_VERSION = "2025-06-18"
SERVER_INFO = {"name": "qimono-gemma-tools", "version": "1.0.0"}

TOOLS = [
    {
        "name": "qiskit_docs_search",
        "description": "Keyword-search the offline quantum corpus "
                       "(Qiskit docs chapter 1, PennyLane intro, curated "
                       "skill packs). Returns ranked chunks.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "k": {"type": "integer", "default": 5},
            },
            "required": ["query"],
        },
    },
    {
        "name": "run_qiskit_snippet",
        "description": "Execute a Python snippet inside the harness venv "
                       "(qiskit + qiskit-aer preinstalled, no network). "
                       "Returns pass/fail plus output or traceback tail.",
        "inputSchema": {
            "type": "object",
            "properties": {"code": {"type": "string"}},
            "required": ["code"],
        },
    },
    {
        "name": "get_skill",
        "name_hint": "quantum-basics|python-basics|qiskit-basics",
        "description": "Return a full curated skill pack (markdown).",
        "inputSchema": {
            "type": "object",
            "properties": {
                "name": {"type": "string",
                         "enum": ["quantum-basics", "python-basics",
                                  "qiskit-basics"]},
            },
            "required": ["name"],
        },
    },
]


def tool_call(name, args):
    if name == "qiskit_docs_search":
        chunks = search_chunks(args["query"], k=int(args.get("k", 5)))
        if not chunks:
            return "no matches"
        return "\n\n".join(
            f"[{c['source']} · {c['title']} · score {c['score']}]\n{c['body']}"
            for c in chunks)
    if name == "run_qiskit_snippet":
        ok, out = run_snippet(args["code"])
        return ("PASS\n" if ok else "FAIL\n") + out
    if name == "get_skill":
        path = HERE / "skills" / f"{args['name']}.md"
        return path.read_text(encoding="utf-8")
    raise ValueError(f"unknown tool: {name}")


def handle(msg):
    method = msg.get("method")
    mid = msg.get("id")
    is_notification = "id" not in msg

    if method == "initialize":
        return {"jsonrpc": "2.0", "id": mid, "result": {
            "protocolVersion": PROTOCOL_VERSION,
            "capabilities": {"tools": {}},
            "serverInfo": SERVER_INFO}}
    if method in ("notifications/initialized",):
        return None
    if method == "ping":
        return {"jsonrpc": "2.0", "id": mid, "result": {}}
    if method == "tools/list":
        clean = [{k: v for k, v in t.items() if k != "name_hint"}
                 for t in TOOLS]
        return {"jsonrpc": "2.0", "id": mid, "result": {"tools": clean}}
    if method == "tools/call":
        params = msg.get("params") or {}
        try:
            text = tool_call(params.get("name"),
                             params.get("arguments") or {})
            return {"jsonrpc": "2.0", "id": mid, "result": {
                "content": [{"type": "text", "text": text}],
                "isError": False}}
        except Exception as e:
            return {"jsonrpc": "2.0", "id": mid, "result": {
                "content": [{"type": "text", "text": f"{type(e).__name__}: {e}"}],
                "isError": True}}
    if is_notification:
        return None
    return {"jsonrpc": "2.0", "id": mid, "error":
            {"code": -32601, "message": f"unknown method: {method}"}}


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue
        resp = handle(msg)
        if resp is not None:
            print(json.dumps(resp), flush=True)


if __name__ == "__main__":
    main()
