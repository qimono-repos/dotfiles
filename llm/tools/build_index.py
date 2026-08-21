#!/usr/bin/env python3
# Builds the SQLite FTS5 keyword index consumed by the gemma harness.
# Sources: skills/*.md + corpus/**/*.md. Zero model RAM cost by design.
#
# Usage: tools/build_index.py   (safe to re-run; rebuilds index/ from scratch)

import sqlite3
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent
DB = HERE / "index" / "corpus.db"
MAX_CHARS = 1800          # ~450 tokens per chunk
SOURCES = [HERE / "skills", HERE / "corpus"]


def strip_front_matter(text):
    if text.startswith("---"):
        parts = text.split("---", 2)
        if len(parts) >= 3:
            return parts[2].strip("\n")
    return text


def doc_title(text, fallback):
    for line in text.splitlines():
        if line.startswith("# "):
            return line[2:].strip()
    return fallback


def chunks_of(text):
    """Split markdown into heading-scoped chunks, merged up to MAX_CHARS."""
    text = strip_front_matter(text)
    sections, cur_title, buf = [], "(intro)", []
    for line in text.splitlines():
        if line.startswith("## "):
            if buf:
                sections.append((cur_title, "\n".join(buf).strip()))
            cur_title, buf = line[3:].strip(), [line]
        else:
            buf.append(line)
    if buf:
        sections.append((cur_title, "\n".join(buf).strip()))

    merged, acc = [], ""
    for title, body in sections:
        if not body:
            continue
        candidate = f"{acc}\n\n[{title}]\n{body}" if acc else f"[{title}]\n{body}"
        if len(candidate) > MAX_CHARS and acc:
            merged.append(acc)
            acc = f"[{title}]\n{body}"
        else:
            acc = candidate
    if acc:
        merged.append(acc)
    return merged


def main():
    rows, seen = [], set()
    for base in SOURCES:
        for path in sorted(base.rglob("*.md")):
            rel = str(path.relative_to(HERE))
            if rel in seen:
                continue
            seen.add(rel)
            text = path.read_text(encoding="utf-8")
            title = doc_title(strip_front_matter(text), path.stem)
            for i, chunk in enumerate(chunks_of(text)):
                if chunk.strip():
                    rows.append((rel, f"{title} · part {i + 1}", chunk))

    DB.parent.mkdir(parents=True, exist_ok=True)
    if DB.exists():
        DB.unlink()
    con = sqlite3.connect(DB)
    con.execute("CREATE VIRTUAL TABLE chunks USING fts5("
                "source UNINDEXED, title UNINDEXED, body)")
    con.executemany("INSERT INTO chunks VALUES (?,?,?)", rows)
    con.commit()

    n_files = len(seen)
    print(f"indexed {len(rows)} chunks from {n_files} files -> {DB}")
    print(f"db size: {DB.stat().st_size // 1024} KiB")
    return 0 if rows else 1


if __name__ == "__main__":
    sys.exit(main())
