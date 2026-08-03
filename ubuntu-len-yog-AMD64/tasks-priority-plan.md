# Tasks priority plan — AI compute / credit aware

**Goal:** finish feedback through **## Hardware** with maximum durable value if the session dies mid-way.  
**Rule:** cheap, high-leverage text/structure first; network/build/daemon experiments last.

---

## Priority bands

| Band | AI cost | Human/risk | Examples |
|------|---------|------------|----------|
| **P0** | Minimal tokens | None | Plan files, renames, heading fixes, terminology sweep |
| **P1** | Low | Low | Doc rewrites, mermaid, teach-ins (stow, AMD-V, Shepherd), README VPS |
| **P2** | Medium | Medium | Manifest edits, stow-source package trees, tests/ rename, channels notes |
| **P3** | High | Higher | quantum-host .NET/Rust research+scm, Nix ranking, KDE Connect, LazyVim tree |
| **P4** | Highest | Highest | Guix browser install, snap remove, Shepherd/podman daemon, SD-card home experiment |

Work **P0 → P1 → P2**; stop cleanly before P3/P4 if credit is tight. P4 needs your OK for snap uninstall.

---

## Ordered backlog

### P0 — do first

| ID | Task | Feedback | Status |
|----|------|----------|--------|
| T01 | Create `feedback-plan.md` + `tasks-priority-plan.md` | meta | `[x]` |
| T02 | Rename `stow/` → `stow-source/`; update scripts/docs | F8 | `[x]` |
| T03 | Rename `examples/` → `tests/smoke-tests/` (+ `stubs/`) | F11 | `[x]` |
| T04 | Terminology: helper → tool/utility in pack + `~/AGENTS.md` | F9 | `[x]` |
| T05 | README: ranking aspirational; Qimono/Ying-Yang stage 1; Related **locations** | F1,F13 | `[x]` |

### P1 — high value docs

| ID | Task | Feedback | Status |
|----|------|----------|--------|
| T06 | Teach: why `.zshrc.d` (compose vs replace) | F8 | `[x]` |
| T07 | Teach: AMD-V vs Hyper-V / VT-x + Android emulator | F14 | `[x]` |
| T08 | Teach: Guix **Shepherd** vs systemd (not Hurd default) | F3 | `[x]` |
| T09 | Teach + decide: portable `$HOME` on SD (`qimono-nomad`) | F15 | `[x]` |
| T10 | Mermaid architecture diagrams in README / docs | F5 | `[x]` |
| T11 | `ubuntu/vps/README.md` — Hostinger, AWS, Linode, Hetzner | F2 | `[x]` |
| T12 | Quantum: Jupyter localhost + browser strategy | F12 | `[x]` |
| T13 | Package ranking + **Nix as #5** | F1,F7 | `[x]` |
| T14 | `MACHINE.md` Hardware: AMD-V teach-in section | F14 | `[x]` |

### P2 — structure / manifests

| ID | Task | Feedback | Status |
|----|------|----------|--------|
| T15 | `base.scm`: emacs, neovim, kdeconnect; browser comments | F4,F6 | `[x]` |
| T16 | Document/extend `channels.scm` (nonguix; Wilson referent) | F4 | `[x]` |
| T17 | Stow packages: `emacs/`, `nvim/` skeletons | F10 | `[x]` README skeletons (no live stow yet) |
| T18 | Stow `vega/mcp/` Amazon MCP pointers | F10 | `[x]` pointer README + Amazon doc URL |
| T19 | Scaffold `ubuntu-mini-pc/` README | F2,F13 | `[x]` |
| T20 | Update `stow-apply.sh`, bootstrap paths after rename | F8 | `[x]` |
| T21 | Sync `~/AGENTS.md` with stage-1 + ranking + Nix | F1 | `[x]` |

### P3 — heavy design / research (defer if low credit)

| ID | Task | Feedback | Status |
|----|------|----------|--------|
| T22 | Rewrite `quantum-host.scm` for .NET 10 + Rust (+ Nix strategy) | F7 | `[ ]` |
| T23 | Codeium / VSCodium Guix or flatpak path | F6 | `[ ]` |
| T24 | KDE Connect setup doc + verify package | F10 | `[ ]` |
| T25 | Jupyter lab install into quantum-workspace via uv | F12 | `[ ]` |
| T26 | draw.io / LaTeX / UML tooling notes | F5 | `[ ]` |

### P4 — last (max credit + risk; confirm before run)

| ID | Task | Feedback | Status |
|----|------|----------|--------|
| T27 | Guix install Firefox, Epiphany, Chromium | F4,F16 | `[ ]` |
| T28 | Uninstall browser snaps (user-encouraged experiment) | F16 | `[ ]` |
| T29 | Optional second service manager / podman auto-start design | F3 | `[ ]` |
| T30 | Trial user `qimono-nomad` + SD home | F15 | `[ ]` |

---

## Execution slices

1. **Slice A:** T01–T14 — **landed this session**  
2. **Slice B:** T17–T18 next (stow emacs/nvim/vega mcp skeletons — medium, no network)  
3. **Slice C:** T22–T26 research/install  
4. **Slice D:** T27–T30 only with explicit green light  

---

## Session log

| When | Done |
|------|------|
| 2026-08-03 | T01–T16, T19–T21 landed; stow restowed to `stow-source/` |
