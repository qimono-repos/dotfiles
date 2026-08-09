# Feedback plan — from `$HOME/prompt-drafts.md`

**Source:** `/home/qi/prompt-drafts.md` (feedback through **## Hardware** inclusive).  
**Context:** Qimono · Ying-Yang Project 2026/2027 · this Grok session = **Infrastructure**.  
**Pack:** `dotfiles/ubuntu-len-yog-AMD64` (user typo “AMD65” → this folder).  
**Strategy stage:** Guix-first on Ubuntu host = **stage 1** toward Guix-as-OS later.

Companion: [tasks-priority-plan.md](./tasks-priority-plan.md) (AI-credit ordering).

---

## Feedback themes (normalized)

| # | Theme | Intent |
|---|--------|--------|
| F1 | Package ranking is **aspirational**, not law | Prefer Guix when effort/availability allow; document stages |
| F2 | VPS / multi-host layout | `ubuntu/vps` readme (providers); later portable init; `ubuntu-mini-pc` pack |
| F3 | Init / daemons vs systemd | Teach Guix **Shepherd** (not Hurd-as-init for Guix System default); portable service ideas; optional second daemon for podman on Ubuntu |
| F4 | `channels.scm` + Nonguix / community | Browsers (Firefox, Epiphany/GNOME Web, Chromium) need non-canonical channels; David Wilson as referent |
| F5 | Architecture marketing | Mermaid first; draw.io, UML, LaTeX/braket/Greek for quantum; “sell the backbone” |
| F6 | Guix manifests richer | emacs + neovim; shared `.config` across OS; Codeium / VS Code–class editor story |
| F7 | `quantum-host.scm` is serious | .NET 10 + Rust under Guix (creative, Nix allowed); expand ranking with **Nix** |
| F8 | Stow pedagogy | Why `.zshrc.d` not full `.zshrc`; rename `stow/` → **`stow-source/`** |
| F9 | Terminology | Avoid “helper”; use utility/tool/aid |
| F10 | Stow packages grow | nvim (LazyVim), emacs (init.el/evil), KDE Connect, **vega/mcp** Amazon MCP |
| F11 | Tests naming | `examples/` → `tests/{stubs,smoke-tests}` |
| F12 | Jupyter local | Guix-global Notebook + stow config; quantum via uv kernel; browsers Guix-first |
| F13 | Related trees → locations | Fix misleading heading; clarify `ubuntu/` = archive/recopilation |
| F14 | Hardware teach-in | AMD-V vs Hyper-V / VT-x; mobile emulator value for Ying-Yang screens |
| F15 | Portable `$HOME` | Teach + plan SD-card home (`qimono-nomad`); multi-arch caveats |
| F16 | Snap experiment | Uninstall browser snaps; try Guix Firefox / GNOME Web / Chromium |

---

## Acceptance for “through Hardware”

Docs and structure must reflect F1–F14 at least in **written form**; F15–F16 may be planned or partially done if credit remains. Heavy Guix browser builds and snap removal are **execution** items (see priority plan).

---

## Out of scope for this pass

- Full Guix System install  
- Production VPS provisioning  
- Completing multi-arch SD home portability (research + design only unless cheap)  

---

## Status legend

- `[ ]` pending · `[~]` in progress · `[x]` done · `[-]` deferred (credit / risk)

## Progress (2026-08-03, through Hardware feedback)

| Theme | Status |
|-------|--------|
| F1 ranking aspirational + stage 1 | `[x]` docs + AGENTS |
| F2 VPS readme + mini-pc scaffold | `[x]` |
| F3 Shepherd teach-in | `[x]` docs only; no second init installed |
| F4 channels + browser notes | `[x]` channels/base comments; install = P4 |
| F5 mermaid + diagram rationale | `[x]` README; draw.io/LaTeX depth = P3 |
| F6 emacs/neovim in base.scm | `[x]`; Codeium = P3 |
| F7 quantum-host .NET/Rust deep rewrite | `[-]` P3 |
| F8 stow-source + .zshrc.d teach | `[x]` |
| F9 no “helper” | `[x]` sweep |
| F10 nvim/emacs/vega/kdeconnect | `[~]` skeletons + kdeconnect in base.scm |
| F11 tests/smoke-tests | `[x]` |
| F12 Jupyter + browsers strategy | `[x]` docs; uv jupyter install = P3; snap exp = P4 |
| F13 related locations | `[x]` |
| F14 AMD-V teach-in | `[x]` |
| F15 portable HOME | `[x]` teach doc; experiment = P4 |
| F16 snap uninstall / Guix browsers | `[-]` P4 |
