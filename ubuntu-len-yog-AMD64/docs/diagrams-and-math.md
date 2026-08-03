# Diagrams and math — sell the backbone

**Chunk:** P3.6 · Feedback F5

Architecture that screen-first teams never see still needs **marketing-quality** diagrams. Quantum work needs **braket / Greek / LaTeX**.

## Tool stack

| Need | Tool | Install hint |
|------|------|--------------|
| Architecture in git | **Mermaid** in Markdown | No install; GitHub/GitLab/many IDEs render |
| Boxes & arrows UI | **draw.io** (diagrams.net) | Desktop app: snap/`apt`/download; not always in Guix |
| UML-ish | **PlantUML** | `guix install plantuml` (+ graphviz) |
| Graph layouts | **Graphviz** | `guix install graphviz` |
| Formulas | **LaTeX** / MathJax in MD & Jupyter | texlive is heavy; prefer MathJax in notebooks first |
| Quantum notation | LaTeX braket packages / Unicode | See below |

## Mermaid (default in this pack)

Already used in `README.md` and teach-ins. Keep diagrams **next to the claim** they explain.

## draw.io (local)

```bash
# options (pick one later)
# snap install drawio   # rank 3
# flatpak install flathub com.jgraph.drawio.desktop
# or AppImage from diagrams.net
```

Export PNG/SVG into `docs/assets/` when a PR needs a frozen figure.

## PlantUML + Graphviz (Guix)

```bash
guix install plantuml graphviz
# plantuml diagram.puml
```

## LaTeX / quantum notation (lightweight first)

In Markdown / Jupyter (MathJax):

```tex
$$
\lvert \psi \rangle = \alpha \lvert 0 \rangle + \beta \lvert 1 \rangle
$$

$$
\langle \phi \rvert \psi \rangle
$$
```

Full TeX Live on Guix is multi‑GB — **do not** install casually on 73 G free root. Prefer:

1. MathJax in Jupyter/Markdown.  
2. Tiny `tectonic` or remote TeX if you must compile PDFs.  
3. Full `texlive` only on a VPS/build machine.

## UML protocol note

UML is a **notation**, not a single file type. Practically:

- Mermaid `classDiagram` / `sequenceDiagram` for in-repo.  
- PlantUML for classic UML.  
- draw.io for stakeholder decks.

## PPTX governance (later)

Open “cloud slide” stack for architecture reviews is out of P3 — track as product/docs process. Local **draw.io** + exported figures feed slides without PowerPoint dependency.
