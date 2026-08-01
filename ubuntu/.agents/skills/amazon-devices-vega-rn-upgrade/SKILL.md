---
name: "amazon-devices-vega-rn-upgrade"
description: |
  Upgrade a React Native for Vega app to a newer RN version (e.g. 0.72 to 0.83) as a
  STRICT interactive, turn-based workflow. Use when a developer asks to upgrade or migrate
  React Native. Ensures the agent writes a TODO plan and checkpoint into the repo first, then
  executes one phase at a time with required stop points before any code change — instead of
  doing the whole upgrade in one pass. Required on clients that lack MCP prompt support (e.g.
  Codex) where the turn-based workflow document otherwise runs as an autonomous one-shot.
  
version: "1.0.0"
tags: ["vega", "react-native", "upgrade", "migration", "turn-based", "codex"]
---

# React Native for Vega — turn-based upgrade

You are executing an **interactive upgrade protocol**, NOT doing the upgrade in one pass.
This skill is the execution contract for `react_native_for_vega_turn_based_rn_upgrade_workflow.md`.
That workflow document holds the authoritative step content; this skill makes you obey it as a
protocol — which matters on clients (e.g. Codex) that deliver the workflow only as tool-result
reference text rather than as an MCP prompt.

## Non-negotiable rules (read first)

1. **DO NOT upgrade in one shot.** Never batch dependency edits, installs, or builds ahead of
   the workflow. Obeying the protocol in order is the goal, not maximizing forward progress.
2. **Write artifacts BEFORE touching code.** In the working directory, create
   `RN_UPGRADE_TODO_<from>_to_<to>.md` and `.rn-upgrade-checkpoint.json` before editing a single
   source or `package.json` line.
3. **Honor every stop point (YIELD gate).** At each gate below, STOP and wait for the user's
   reply. Do not proceed on your own initiative.
4. **Never claim success without verification** (show build result / test output).
5. **One directory at a time.** Operate on the specified working dir; for monorepos, run once
   per package.

## Step 0 — Load the canonical workflow

Fetch the real step content, then follow it as an execution protocol (not a summary):
- `list_documents(documentType="WORKFLOW", target_platform={device_os:["vega_os"]})`
- `read_document("react_native_for_vega_turn_based_rn_upgrade_workflow.md")`

## Phase 1 — Initialization & detection (Steps 0–8)

1. Resume check: if `.rn-upgrade-checkpoint.json` exists, load it and jump to its saved
   phase/step. Otherwise start fresh.
2. Validate the project (`package.json` present, is an RN app); detect current RN + React.
3. Detect package type; for RN 0.83+ run early Carousel v1 detection.
4. Environment check (Node >= 22.14.0; package manager).

### GATE 1 — STEP 8: Confirm with user
Present the summary and STOP. Wait for `yes`/`no` before generating the TODO:
```
Upgrade Summary
Current: React Native <cur> + React <react_cur>
Target:  React Native <target>
Span:    <N> minor versions
Environment: Node <ver> [OK/upgrade], PM: <npm/yarn/pnpm>
Ready to generate upgrade TODO? (yes/no)
```

## Phase 1.5 — Dependency availability (Step 8.5)
For each target package in the guide that is present in this project's `package.json`, run
`npm view <pkg>@<target> version`. Flag anything not found in the TODO. Do NOT block — proceed
with available packages and note the rest.

## Phase 2 — Knowledge loading & TODO generation (Steps 9–15)

1. Discover and load the RNV upgrade-guide knowledge files via `list_documents`/`read_document`.
2. Extract breaking changes; assign priority (CRITICAL / HIGH / MEDIUM / LOW).
3. Write `RN_UPGRADE_TODO_<from>_to_<to>.md` into the working dir (grouped by priority).
4. Write `.rn-upgrade-checkpoint.json`:
```json
{
  "phase": "INTERACTIVE",
  "project_path": "<abs path>",
  "current_version": "0.72.0",
  "target_version": "0.83.0",
  "todo_file": "RN_UPGRADE_TODO_0.72_to_0.83.md",
  "completed_count": 0,
  "total_count": 20,
  "selected_change_id": null,
  "requires_carousel_migration": false,
  "carousel_files": [],
  "timestamp": "<ISO8601>"
}
```

### GATE 2 — Setup summary
Show the setup summary (versions, change count by priority, TODO path), then enter Phase 3.
Do NOT start implementing changes yet.

## Phase 3 — Interactive upgrade loop (Steps 16–25)

**This is a CONTINUOUS LOOP. Do not exit until the user types `exit`.** Each turn:

1. Display pending changes grouped by priority, plus the command menu:
   `[1-N]` select a change and view its guide · `complete` mark selected done · `status` ·
   `help` · `exit` save and finish.
2. **STOP and wait** for the user's choice (a stop point every turn).
3. On a number: show that change's guide; offer to implement ONLY that change; after it is
   applied (or the user did it manually and typed `complete`), mark it done.
4. Update `.rn-upgrade-checkpoint.json` after each completed change (resume support).
5. Loop back to the menu. Never auto-advance through multiple changes.

## Phase 4 — Build verification
Only after the user drives the changes: run the build and show real output. On errors, use the
common build-errors knowledge to propose fixes one at a time. Never report success without the
build result.

## If tempted to shortcut
If you are about to "just do the whole upgrade," STOP — that is the exact failure this skill
prevents (tracked in PROJVEGA-406953). Re-read rules 1–3 and return to the current gate.
