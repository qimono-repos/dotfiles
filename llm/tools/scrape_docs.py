#!/usr/bin/env python3
# Offline-docs scraper for the gemma harness corpus.
# Fetches a curated URL list while online and stores clean markdown under
# corpus/. Idempotent-ish: re-running overwrites the same filenames.
#
# Usage: tools/scrape_docs.py [--only qiskit|pennylane]

import argparse
import datetime
import sys
import urllib.request
from html.parser import HTMLParser
from pathlib import Path

HERE = Path(__file__).resolve().parent.parent

DOCS = [
    ("qiskit", "qiskit-course-basics-of-quantum-information.md",
     "https://learning.quantum.ibm.com/course/basics-of-quantum-information"),
    ("qiskit", "qiskit-guide-simulate-with-qiskit-aer.md",
     "https://docs.quantum.ibm.com/guides/simulate-with-qiskit-aer"),
    ("qiskit", "qiskit-api-circuit.md",
     "https://docs.quantum.ibm.com/api/qiskit/circuit"),
    ("qiskit", "qiskit-guide-operators-overview.md",
     "https://docs.quantum.ibm.com/guides/operators-overview"),
    ("qiskit", "qiskit-guide-circuit-library.md",
     "https://docs.quantum.ibm.com/guides/circuit-library"),
    ("pennylane", "pennylane-tutorial-qubit-rotation.md",
     "https://pennylane.ai/qml/demos/tutorial_qubit_rotation"),
    ("pennylane", "pennylane-codebook-I1.md",
     "https://codebook.xanadu.ai/I.1"),
]

SKIP_TAGS = {"script", "style", "nav", "header", "footer", "svg", "button",
             "form", "noscript", "iframe", "select"}
BLOCK_TAGS = {"p", "div", "section", "article", "br", "ul", "ol", "table",
              "tr", "li", "h1", "h2", "h3", "h4", "h5", "h6", "pre", "blockquote"}
HEADINGS = {"h1": "# ", "h2": "## ", "h3": "### ", "h4": "#### "}


class Extractor(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.out = []
        self.skip_depth = 0
        self.code_depth = 0
        self.li_open = False

    def handle_starttag(self, tag, attrs):
        if tag in SKIP_TAGS:
            self.skip_depth += 1
        elif tag == "pre":
            self.code_depth += 1
            self.out.append("\n```\n")
        elif tag == "code" and not self.code_depth:
            self.out.append("`")
        elif tag == "li":
            self.li_open = True
            self.out.append("\n- ")
        elif tag in HEADINGS:
            self.out.append("\n\n" + HEADINGS[tag])
        elif tag in BLOCK_TAGS:
            self.out.append("\n")

    def handle_endtag(self, tag):
        if tag in SKIP_TAGS and self.skip_depth:
            self.skip_depth -= 1
        elif tag == "pre":
            self.code_depth = max(0, self.code_depth - 1)
            self.out.append("\n```\n")
        elif tag == "code" and not self.code_depth:
            self.out.append("`")
        elif tag in BLOCK_TAGS:
            self.out.append("\n")
        if tag == "li":
            self.li_open = False

    def handle_data(self, data):
        if self.skip_depth or not data.strip():
            return
        if self.li_open and self.out and not self.out[-1].endswith(" "):
            pass
        self.out.append(data)

    def text(self):
        raw = "".join(self.out)
        lines = [ln.rstrip() for ln in raw.splitlines()]
        cleaned, blank = [], False
        for ln in lines:
            s = ln.strip()
            if not s:
                if blank:
                    continue
                blank = True
                cleaned.append("")
            else:
                blank = False
                cleaned.append(ln)
        return "\n".join(cleaned).strip() + "\n"


def fetch(url):
    req = urllib.request.Request(url, headers={"User-Agent": "qimono-corpus-bot/1.0"})
    with urllib.request.urlopen(req, timeout=45) as r:
        return r.read().decode("utf-8", errors="replace")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--only", choices=["qiskit", "pennylane"])
    args = ap.parse_args()

    ok = failed = 0
    today = datetime.date.today().isoformat()
    for group, fname, url in DOCS:
        if args.only and group != args.only:
            continue
        dest = HERE / "corpus" / group / fname
        try:
            html = fetch(url)
            ex = Extractor()
            ex.feed(html)
            body = ex.text()
            if len(body) < 500:
                raise ValueError(f"suspiciously short extract ({len(body)} chars)")
            dest.write_text(
                f"---\nsource: {url}\nfetched: {today}\n---\n\n{body}",
                encoding="utf-8")
            print(f"OK    {fname:55s} {len(body):>7d} chars")
            ok += 1
        except Exception as e:
            print(f"MISS  {fname:55s} {e}")
            failed += 1
    print(f"\n{ok} fetched, {failed} failed -> {HERE / 'corpus'}")
    return 1 if ok == 0 else 0


if __name__ == "__main__":
    sys.exit(main())
