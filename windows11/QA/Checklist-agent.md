# QA — Agent checklist (windows11)

Anti false-victory: record **evidence** (real command output), not intent. Run
in order; tick only what actually passes.

## Tier-1 CLI / editors

- [ ] `rg --version` → 1 byte match on a test string (evidence: output saved)
- [ ] `fd --version`
- [ ] `fzf --version`
- [ ] `fastfetch --version` → single-shot run OK in-prompt
- [ ] `nvim --version | Select-Object -First 1`
- [ ] `emacs --version | Select-Object -First 1`
- [ ] `oh-my-posh --version` → fresh shell renders Catppuccin prompt
- [ ] `node --version` ≥ 24; `uv --version`; `python --version` is 3.13 real build (not Store stub)

## Python / uv policy

- [ ] `$env:UV_PYTHON_PREFERENCE` = `only-system`
- [ ] `$env:UV_PYTHON_DOWNLOADS` = `never`
- [ ] `$env:UV_PYTHON` resolves to python.org build (Test-Path true)
- [ ] `uv run python` in workspace uses the pinned python

## Profile (stow analog)

- [ ] `$PROFILE` exists and is the pack copy
- [ ] Profile.d/ has 00·15·20·25·30·40·42·50 snippets
- [ ] New shell launches fastfetch once; `cls` reprints it
- [ ] `too` / `powerofff` functions defined

## Quantum (currently DEFERRED — qiskit/rustworkx win_arm64; see doc/BUILD-QUANTUM-WIN_ARM64.md)

- [ ] `QIMONO_QUANTUM_HOME` workspace exists with pyproject.toml (qiskit under `quantum` extra)
- [ ] `uv lock` + `uv sync --extra dev` resolved (base deps: numpy/matplotlib/jupyterlab/notebook/ipykernel)
- [ ] `uv run pytest tests/smoke-tests` → **python (base) PASS; qiskit/pennylane auto-skipped** (not errors)
- [ ] `uv run python -c "import numpy, matplotlib"` (evidence) — qiskit import NOT expected until resume
- [ ] Resume gate: `scripts/install-build-toolchain.ps1` env block applies; then `uv sync --extra quantum --extra dev`

## Reboot-persistence

- [ ] After R1: fresh pwsh still renders prompt; uv policy envs persist
- [ ] After R2: smokes pass again; winget package list unchanged semantically

## Budget/frozen flags

- [ ] `java -version` still 25.0.3 (JBR) — Java untouched
- [ ] No `gemma4:e2b` auto-pull happened (~7.2 GB) — stays deferred/manual