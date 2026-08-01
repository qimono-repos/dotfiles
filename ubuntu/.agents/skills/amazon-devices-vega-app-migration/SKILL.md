---
name: "amazon-devices-vega-app-migration"
description: |
  Migrate an existing Fire TV / FOS app to a React Native for Vega app as a STRICT, phase-by-phase,
  step-by-step protocol. Use when a developer asks to migrate, port, or convert an app to Vega.
  Ensures the agent runs the migration workflow's phases in order (typically VALIDATE -> PLAN ->
  EXECUTE -> BUILD & VERIFY), completes each phase FULLY and passes its gates before moving to the
  next (advancing on its own, no unnecessary stops), executes every step linearly without skipping,
  writes the migration guide before any code, and generates real content from the guide instead of
  stubs or fabricated screens/data. Required on clients that lack MCP-prompt
  support (e.g. OpenAI Codex) and useful across models (Claude, GPT) that otherwise vary in how
  faithfully they follow the multi-phase workflow.
  
version: "1.1.0"
tags: ["vega", "migration", "port", "turn-based", "phased", "codex"]
---

# App migration to Vega — phase-by-phase, step-by-step

You are executing a **disciplined, phase-by-phase migration protocol**, NOT doing the migration in one
pass. This skill is the execution contract for the FOS → Vega migration workflow. The workflow
documents hold the authoritative step content; this skill makes you **obey them in order and in full**
— which matters on clients (e.g. Codex) that deliver a workflow only as tool-result reference text,
and across models whose migration behavior otherwise varies.

This skill enforces *discipline* (ordering, per-step completeness, no fabrication). It does NOT
replace or restate the workflow's steps — always load and follow the workflow docs for the real
content.

## Non-negotiable rules (read first)

1. **DO NOT migrate in one shot.** Never race ahead to generating the Vega app. Obeying the phase
   order and completing each step is the goal, not maximizing forward progress.
2. **Run the workflow's phases in order, one after another** (typically VALIDATE → PLAN → EXECUTE →
   BUILD & VERIFY). Do not start a phase until the previous one is **fully complete** — every step
   done and every gate in that phase's workflow doc satisfied. Move to the next phase on your own once
   the current phase is complete; do NOT stop to ask permission between phases. The gate between phases
   is *completeness*, not a human pause.
3. **Words before code.** Produce the migration guide FIRST (PLAN). Generate no app code until the
   guide is complete (including its coverage/scorecard step, where the workflow defines one).
4. **Execute every step in the exact order the workflow lists, one at a time.** NEVER skip, merge,
   reorder, summarize-instead-of-do, or defer a step. If a step is meant to produce something (a guide
   section, a screen, an asset, a manifest entry), that output MUST exist before the next step.
5. **EVERYTHING comes from the FOS source app — fabricate NOTHING.** This is the #1 failure and the
   hardest rule in this skill. Every artifact in the migrated app MUST trace to a real thing that
   exists in the FOS source (or the guide that inventoried it). You are **transcribing an existing app,
   not designing a new one.**
   - **Assets (icons, images, drawables, fonts, media):** use ONLY the actual asset files from the FOS
     source (copied/transported per the workflow). NEVER generate, redraw, substitute, rename, or
     invent an icon or image. If a referenced asset is missing from the source, do NOT create a
     replacement — record it in NextSteps.md as a gap and leave the reference pointing at the real
     (missing) name. A generated/placeholder icon is a DEFECT.
   - **Screens & routes:** generate exactly the screens the FOS app has, no more and no fewer. NEVER add
     a screen, tab, route, or navigation destination the source does not contain. NEVER drop one either.
   - **Content & data:** rows, items, titles, labels, catalog entries, and sample data MUST be the FOS
     app's REAL data (imported from the transported data files), never invented, re-typed, guessed, or
     filled with lorem/example values. If the app fetches data from an API, wire the real endpoint — do
     not hardcode a made-up array.
   - **Strings, colors, dimensions, styles:** take the FOS app's real values (from its resources/guide),
     not defaults you assume or invent.
   - A screen reduced to a name/title, a "Coming soon"/"Go Back"-only view, an empty container, or a
     `// TODO` placeholder is a DEFECT — not a migrated screen.
   **Rule of thumb: if you cannot point to the FOS source artifact (or the guide entry that captured it)
   that a given icon / screen / string / data value came from, you fabricated it — remove it and go get
   the real one.** (Where the workflow also defines a stub/fabrication-prevention step or gate — e.g. a
   data-file / asset transport step — honor it too, but do not rely on it existing.)
6. **Velocity is the trap.** If you find yourself generating many items quickly — to save time, or
   under context pressure — STOP. Producing items fast while dropping the per-item "load the required
   reference → implement fully → verify" discipline is the single most common cause of a broken
   migration. Speed NEVER justifies a placeholder.
7. **Never claim success without verification.** Show the evidence — sections written, files created,
   gate/sweep results, build output.

## Step 0 — Load the canonical workflow

Fetch the real step content, then follow it as an execution protocol (not a summary):
- Use `list_documents` or filesystem lookup to find the migration workflow set (the router/entry
  workflow + its per-phase sub-workflows).
- Read the router/entry workflow first — it auto-detects the source app type and dispatches to the
  matching orchestrator; then read each phase sub-workflow as you ENTER that phase. Follow whatever
  phases and steps those documents define — this skill assumes no fixed step content of its own.

## Step 0.5 — BLOCKING GATE: Create the checkpoint (BEFORE touching anything else)

🚨 **You CANNOT proceed to any workflow step until BOTH files exist and are confirmed.**

In the working directory, create and maintain:
- `MIGRATION_TODO.md` — the checklist of the current phase's workflow steps (derived from the doc you
  just read), each marked pending/done.
- `.migration-checkpoint.json` — resumable state: current phase, current step, completed counts, and
  the per-item evidence log (below).

**GATE VERIFICATION** — confirm both files exist before any workflow step. If either file is missing,
you have NOT started the protocol. Create them now. Do NOT proceed until both exist.

Update the checkpoint after every step. On resume, read the checkpoint and continue from its saved
position. Mark a step **done only after its output is produced and verified** — never in advance.

### Per-item evidence (for any step that loops over inventoried items)

When a step processes many items of a kind the workflow inventories (e.g. one entry per screen /
component / layout / asset / data file), write ONE evidence line per item as you complete it.

**Format** — one line per item, pipe-delimited: `<item-id> | <FOS source path> | <output file written> | done`

**Why this works**: you cannot fill in a real FOS source path for a fabricated item. If you cannot
name the source path, the item is fabricated — do not log it as done; remove it and retrieve the real
source artifact.

**Rules**:
- Write ONE line IMMEDIATELY after completing each item — do NOT batch many items and log them all at once.
- The FOS source path column catches fabrication: an invented screen/icon/data has no real path.
- The output file column catches skips: an item with no output file was not actually done.
- If you cannot fill all 3 columns honestly → the item is not done. Stop and fix it.
- Update `.migration-checkpoint.json` evidence_log array with each line as you go.

## Phases — run them in order, gated by completeness (no unnecessary stops)

Work through the workflow's phases **continuously, one after another**. Within a phase, work
step-by-step, honoring the workflow's in-phase BLOCKING GATES. At each **phase boundary** do NOT stop
to ask permission: verify the completeness check below, briefly report what the phase produced (with
evidence), then proceed to the next phase on your own. The transition gate is *completeness* — you may
only advance when the current phase's completeness check passes; if it fails, finish the missing work
first. The four major phases (typically): **VALIDATE → PLAN → EXECUTE → BUILD & VERIFY** (follow the
workflow's actual phase list, including any review/perf phases it defines after build).

### PHASE TRANSITION PROTOCOL (mandatory — no exceptions)

Before advancing from one phase to the next, you MUST:
1. Run the phase's completeness check (defined per-phase below).
2. Output a `[PHASE_GATE]` block containing:
   - Steps completed (list with checkmarks)
   - Steps incomplete (list, or "none")
   - Finalize gates passed (each gate with pass/fail)
   - Unit counts: total, mapped, partial, manual_review, pending
   - VERDICT: PHASE COMPLETE → proceeding to next, OR PHASE INCOMPLETE → fixing what
3. If ANY step is incomplete, ANY gate fails, or pending > 0 → **STOP. Do NOT proceed.** Fix the
   incomplete work first. The phase transition block with a failing verdict is the evidence you caught
   yourself — it is NOT a failure, it is the protocol working.

A phase transition without this block is a DEFECT — you skipped the self-check.

### VALIDATE — complete when
It is confirmed a valid, in-scope app for this flow, and the app name + package identity are resolved
to the app's REAL package (never a placeholder — a wrong package silently breaks Vega launch). Report,
then continue to PLAN.

### PLAN — complete when
The migration guide contains every mandatory section AND the workflow's coverage/scorecard step (where
defined) reports its coverage with no un-analyzed / un-mapped units left unaccounted. This is the
**words-before-code** boundary: no app code until the guide is complete. Report the scorecard summary +
guide path, then continue to EXECUTE.

### EXECUTE — complete when
The workflow's reconciliation / final-validation step passes AND the mechanical anti-skip sweep below
finds no hits AND the post-generation screen gate below passes for every generated screen.
Report all results, then continue to BUILD & VERIFY.

#### POST-GENERATION SCREEN GATE (after each screen file is written in EXECUTE)

Immediately after writing each screen file, verify it is NOT a stub:

1. **Real data source**: Does it import from a data directory, API module, or shared logic module?
   → MUST be YES for any screen that renders content. Exception: screens with only static text
   (dialogs, wizards with hardcoded prompts) may have no data import.
2. **Shared UI composition**: Does it use at least one component from the shared UI layer built in
   the EXECUTE pre-screen steps? → MUST be YES for content screens.
3. **No stub signatures**: Does the file contain ANY of: a "Go Back" button as the only interactive
   element; "Coming soon" / "placeholder" / "TODO" / "not implemented" as visible rendered text;
   the screen name rendered as the only content; an empty container as the entire return?
   → ANY match = **STUB DEFECT**.

If ANY check fails → DELETE the file and regenerate it properly from the guide's screen section,
the copied data file it consumes, and the shared components. Do NOT proceed to the next screen
until this gate passes.

### BUILD & VERIFY — complete when
The workflow's build-and-verify phase (and any review/performance phases it defines) has run and its
result is reported. Do not declare the migration done before this phase; skipping it is exactly the
kind of dropped-phase failure this skill exists to prevent. Report the build/verify outcome as the
final status.

## Mechanical anti-skip + anti-fabrication sweep (end of the code-generation phase)

This is a **deterministic** check that fires regardless of how "done" you feel. Resolve the required
patterns/counts/inventory from the workflow + guide + KB + FOS source at runtime (do not hardcode any
app's screens, service ids, or counts). Run greps/comparisons such as:
- **Placeholder/stub signature:** search generated code for leftover "TODO", "placeholder",
  "Coming soon", or a component whose body is essentially just a title of the screen's own name →
  any hit = an un-migrated stub → NOT done; rebuild it from its guide entry.
- **Fabricated-asset signature:** for every icon/image/font/media reference in the generated app, the
  referenced asset file MUST exist in the set transported from the FOS source. Any asset in the Vega app
  that is NOT present in the FOS source = fabrication → NOT done; replace with the real FOS asset or
  record the gap in NextSteps.md. Also flag any placeholder/sample data literals → fabricated content.
- **Screen/route count parity signature:** the count and identity of generated screens/routes MUST match
  the FOS source inventory (from the guide) — no extra screens/routes that the source lacks, and none
  missing. A surplus = fabrication; a shortfall = a skip. Either = NOT done.
- **Required-companion-output signature:** for any item type whose workflow/KB step mandates extra
  outputs, verify those outputs are present in the count/shape the KB specifies → a shortfall = incomplete.
- **Content-vs-spec signature:** an item whose guide entry lists content (rows/items/actions/data) but
  whose generated file renders none of it → a stub → NOT done.
Any hit blocks phase completion until fixed. This sweep is also the recommended human/CI backstop.

## If tempted to shortcut, go fast, or "fill in the gaps"

If you are about to "just do the whole migration," generate code before the guide is complete, batch
many screens into placeholders, skip a step or gate, **or invent an icon / image / screen / string /
data value because the real one is inconvenient to find or missing** — STOP. Fabrication is the #1
failure this skill prevents. You are transcribing the FOS app, not designing a new one: if you can't
trace an artifact to a real FOS source file or guide entry, do not create it — retrieve the real one or
record the gap in NextSteps.md. These failures produce stub screens, invented content, wrong-looking
icons, missing/extra screens, wrong package identity, and unlaunchable apps. Re-read rules 1–7
(especially rule 5) and return to the current step.

## Context Pressure Rule

If at any point:
- You have read 2+ source files without writing their analysis, OR
- You are about to generate more than 1 screen/component without per-item evidence, OR
- You notice yourself abbreviating, batching, or skipping sub-steps to "finish faster", OR
- Context/token limits are approaching and you feel pressure to "wrap up"

→ **STOP IMMEDIATELY.** You are in the velocity trap.

**Action**: Write what you have. Update the checkpoint. Tell the user you have completed X of Y items
in this step and need to continue in the next turn to maintain per-item discipline, stating where
you will resume from.

This is NOT a failure — it is the protocol working correctly. A paused migration resumed correctly
**always** beats a fast migration full of stubs. The checkpoint exists specifically for this: save
state, stop cleanly, resume later with full fidelity.

**Do NOT** attempt to "finish" by batching, abbreviating, or producing placeholders under context
pressure. A stub screen is a permanent defect; a clean pause is recoverable.

## "Continue" Does Not Mean "Skip"

When the user says "continue" (or similar), it means "keep going WITH the same discipline."
It does NOT mean:
- Skip remaining sub-steps to reach the next phase faster
- Batch multiple items into one pass
- Abbreviate analysis to save tokens
- Generate stubs/placeholders to show progress
- Collapse nested sub-steps (e.g., tracing, finalize gates) as "optional"

On receiving "continue": read the checkpoint → identify the exact next incomplete item →
resume from that item → maintain the same one-at-a-time, read-write-verify protocol.
