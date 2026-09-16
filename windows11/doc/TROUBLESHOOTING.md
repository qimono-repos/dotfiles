# Windows11 (ARM64) Pack — Troubleshooting

Hand-curated from real failures hit during 2026-09-16 provisioning of Yin.

---

## Python / uv

### `python` opens the Microsoft Store or is a stub
The Windows Apps Execution Authoring alias shadows the real interpreter.
- **Fix:** `install-uv-python.ps1` re-pins `UV_PYTHON` to
  `C:\Users\qi\AppData\Local\Programs\Python\Python313-arm64\python.exe`.
- Verify: `uv run python -c "import sys; print(sys.version)"`.

### uv installs its own python anyway / ignores system
- Check env: `UV_PYTHON_PREFERENCE=only-system`, `UV_PYTHON_DOWNLOADS=never`.
- They're User-scope; a pet new shell inherits them only if you logged in fresh.

### `.venv` lacks pip
uv envs don't ship pip by default. Use `uv pip` / `uv run` instead of `python -m pip`.
If you truly need pip: `uv pip install pip`.

---

## PowerShell snippets / profile

### Profile won't load
- `$PROFILE` resolves through OneDrive; confirm file
  `C:\Users\qi\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` exists.
- Snippets live in `Profile.d/` relative to it; the profile **must** contain the
  `Get-ChildItem Profile.d` loop from `profile-source/`.

### Snippet that throws kills the whole prompt
Every `Profile.d/*.ps1` should be try/catch-guarded. Follow the pattern in the
existing `00`/`20` files — a failing snippet must never block the shell.

---

## Network budget monitor

### Monitor reports 0 MB when we know we downloaded a lot
You have a **pre-v2** state file. The old version snapped `baseline` and re-anchored
on counter reset, wiping the total (happened 2026-09-16 — 307 MB vanished).
- **Fix:** `check-network-budget.ps1 -Reset` and re-anchor deliberately.

### `Get-NetAdapterStatistics` Name changed / adapters appear missing
Keys are OS adapter names; they can shuffle (Wi-Fi, Wi-Fi 5, Ethernet 2, …).
Unknown adapters are re-baselined at arrival with zero contribution. Nothing is lost;
you may see a "free" slice of a newly-appeared adapter until its next counter read.

### Script exits 1 spuriously
Exit 1 = budget reached (by design, so build scripts abort). Check
`accumulatedBytes` vs `budgetBytes` in `%USERPROFILE%\.qimono\network-budget.json`;
raise budget with `-BudgetBytes` if the cap was just conservative.

---

## Ghostty / fonts

### `ghostty` not on PATH
The community **winghostty** fork installs portable to `C:\Users\qi\Tools\winghostty\`.
`bin` was appended to user PATH; a stale `PATH` in an open terminal needs a restart.

### Fonts look wrong / box glyphs
Caskaydia Cove Nerd Fonts install **per-user**; terminal must be restarted and the
font selected explicitly in the terminal profile (default monospaced fallback shows
boxes for Nerd Font glyphs).

---

## Quantum / Rust source-builds (reserved for resume)

### `--locked` error on rustworkx
`sdist Cargo.lock` is stale relative to its Cargo.toml; maturin passes `--locked`.
- Use the GitHub **tag tarball** (consistent lock) instead of the sdist, or
- delete sdist `Cargo.lock` + set `[tool.maturin] locked = false`.

### `link.exe not found`
A build script / proc-macro compiled for the **msvc host**. The build toolchain must
be the **gnullvm** toolchain (`RUSTUP_TOOLCHAIN=stable-aarch64-pc-windows-gnullvm`),
not just the target, when using llvm-mingw.

### 59 E0277 / E0308 / E0599 in rustworkx `src/lib.rs`
pyo3 0.29 API change. rustworkx 0.18.1 source targets an older pyo3; the bundled 0.29
lock is wrong for it. See `BUILD-QUANTUM-WIN_ARM64.md` §2 (tag tarball + verify
pyo3 line; fall back to a newer rustworkx that inks its pyo3 bump).

### `zig` as linker fails with `/NOLOGO: unrecognized file extension`
Zig 0.16 removed argv[0] dispatch; `zig cc` is GCC-flavoured and rejects MSVC flags.
Use `aarch64-pc-windows-gnullvm` (rust-lld) + llvm-mingw instead — Zig is no longer
necessary.

### MSVC-ABI vs GNU-ABI wheels
gnullvm builds produce `win_arm64` wheels loading into UCRT CPython — fine. Do NOT
mix with `--target aarch64-pc-windows-msvc` builds in the same env.

---

## Useful one-liners

```powershell
# where is the real python?
(Get-Command python).Source
# is uv policy sane?
Get-ChildItem Env:UV_PYTHON*
# what did we receive since tracking started?
pwsh .\dotfiles\windows11\scripts\check-network-budget.ps1
# ripgrep for a tool
rg -l "TOOLCHAIN" .\dotfiles\windows11
```

---

*Maintainers: keep this file in sync with `../MACHINE.md`, `TOOLCHAIN.md` and
`BUILD-QUANTUM-WIN_ARM64.md` whenever a new failure mode is discovered.*