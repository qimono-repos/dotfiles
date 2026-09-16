# QA — User checklist (windows11)

Human-owned gates: elevation, reboots (R1/R2), GUI, pen ticks.

## Pre-flight

- [ ] Confirmed this laptop is the parity target (Windows 11 ARM64, no
      Java/Temurin changes allowed)
- [ ] Approved ~518 MB budget (tier-1 + node + emacs + quantum; ghostty/community
      optional)

## During install

- [ ] Approved each winget elevation prompt (install-consumed packages)
- [ ] Confirmed no `gemma4:e2b` pull triggered (deferred to manual)
- [ ] Confirmed Java untouched (`java -version` still JBR 25.0.3)

## Post-install (R1 = fresh shell, R2 = after reboot)

- [ ] R1: open a NEW PowerShell — prompt is Catppuccin, fastfetch printed once
- [ ] R1: `codium`, `nvim`, `emacs` all open without error
- [ ] R1: toggle `cls` → fastfetch reappears
- [ ] R2: `uv run pytest tests/smoke-tests` inside quantum workspace passes
- [ ] R2: `ollama list` (if model present) is still empty/unchanged — no big pull

## Blocker escalation

- [ ] Any winget FAIL exit → agent recorded it; decide retry vs defer [ ]