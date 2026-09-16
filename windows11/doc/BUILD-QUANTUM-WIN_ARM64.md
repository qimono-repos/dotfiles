# Building Qiskit for Windows ARM64 (Resume Guide)

**Status: DEFERRED 2026-09-16 (bandwidth decision).** This document captures everything
learned while attempting to source-build qiskit + rustworkx on the Snapdragon
machine (Yin) so a future high-bandwidth session can resume in minutes instead
of re-deriving it.

---

## TL;DR

Qiskit has **no `win_arm64` wheel** on PyPI (only `macosx`, `manylinux`, `win_amd64`).
Its hard dependency `rustworkx` also has **no `win_arm64` wheel**. Building both
from source requires a Rust toolchain + a working linker. On this machine there is
**no Visual Studio, no VS Build Tools, no MSVC SDK** — and installing those is
1–2 GB, which exceeded the session budget. So we:

1. Installed the pieces needed for a **VS-free** source build (all still on disk).
2. Hit a genuinely-broken upstream artifact (`rustworkx 0.18.1` sdist's committed
   `Cargo.lock` is stale; it pre-dates a breaking pyo3 API change).
3. Deferred to a future session rather than burn more bandwidth.

---

## What is already installed (reusable, no re-download)

| Component | Location | Purpose |
|---|---|---|
| RustUP 1.29.1 | `winget` → `~\.rustup\` | Toolchain manager |
| Rust `stable-aarch64-pc-windows-msvc` 1.98.1 | rustup | Host ABI (prefer gnullvm for builds) |
| Rust `stable-aarch64-pc-windows-gnullvm` 1.98.1 | rustup | **The build toolchain** (default linker = `rust-lld`) |
| llvm-mingw `20260908` ucrt-aarch64 | `C:\Users\qi\Tools\llvm-mingw` (177 MB zip, sha256 verified `7fe35f60…ab56`) | clang + Windows UCRT import libs = GNU linker for aarch64 |
| Zig 0.16.0 | winget `zig.zig` | (investigated as linker; not needed — gnullvm uses rust-lld) |
| maturin 1.15.0 | quantum-workspace `.venv` | Rust→Python wheel builder |

### Verified on-Disk Facts (from 2026-09-16)
- `aarch64-pc-windows-gnu` does **not** exist for ARM64. Rust only ships
  `aarch64-pc-windows-msvc` and `aarch64-pc-windows-gnullvm`.
- `rustc --target aarch64-pc-windows-gnullvm -Clinker=<llvm-mingw clang>` **links and
  runs correctly** (tested: 42-returning exe, exit code 0).
- `zig 0.16` dropped argv[0] dispatch — the old "copy zig.exe to cl.exe" trick no
  longer works.
- The `rustworkx 0.18.1` PyPI sdist contains a **stale `Cargo.lock`**. Its
  `Cargo.toml` says `pyo3 = "0.29"`, but 0.29.x changed `map_into_ptr()` and the
  0.18.1 source only compiles against **pyo3 0.28.x** (the lock file still pins
  `pyo3 0.29.0` — inconsistent). Even `cargo update -p pyo3 --precise 0.29.0`
  failed with 59 E0277/E0308/E0599 errors in `src/lib.rs` (`descendants`).

---

## Resume steps (next high-bandwidth session)

### 0. Check budget
```powershell
pwsh .\dotfiles\windows11\scripts\check-network-budget.ps1   # expect ~1 GiB free (approx, for below)
```

### 1. Prepare env (idempotent)
```powershell
# Install/verify rustup + gnullvm toolchain + llvm-mingw, then show env block:
pwsh .\dotfiles\windows11\scripts\install-build-toolchain.ps1        # install
pwsh .\dotfiles\windows11\scripts\install-build-toolchain.ps1 -ShowEnv
```

### 2. Patch `rustworkx` to a buildable state
Use the GitHub **tag tarball**, not the sdist. Then align the dependency line to
the pyo3-era the *source* was written for. Empirically, **0.18.1 source fails
against pyo3 0.29.0** (`map_into_ptr` API change, 59 errors) — the lock in the
sdist appears newer than the source. Try this (falling back as noted):

```powershell
Invoke-WebRequest https://github.com/Qiskit/rustworkx/archive/refs/tags/v0.18.1.tar.gz -OutFile rustworkx.tgz
tar -xf rustworkx.tgz
cd rustworkx-0.18.1
# Check what pyo3 line the v0.18.1 source actually matches:
#   grep -E 'pyo3|numpy' Cargo.toml            # the tag's own Cargo.toml constraint
#   grep -A1 'name = "pyo3"' Cargo.lock        # the tag's own committed lock
# If still /"0.29/" both, then 0.18.1 was released broken; switch to the newest
# rustworkx that inks its pyo3 bump correctly (changelog / PR #1603) — those
# builds "just work" with uv and the gnullvm env.
```

Apply the env block from step 1 **in this shell**, then:
```powershell
<workspace>\.venv\Scripts\maturin.exe build --release --target aarch64-pc-windows-gnullvm --out .\wheels
pip install .\wheels\rustworkx-0.18.1-cp313-cp313-win_arm64.whl
```

### 3. Build qiskit from source similarly
```powershell
uv pip download qiskit==2.5.2 --no-binary qiskit,rustworkx
# qiskit's sdist is cleaner than rustworkx's (no stale-lock problem reported),
# but it also needs the SAME gnullvm env. Build with maturin into wheels dir,
# then point uv at it:
uv pip install --find-links .\wheels "qiskit==2.5.2"
```

### 4. Sync the workspace
```powershell
uv lock --extra quantum && uv sync --extra quantum --extra dev   # re-locks; qiskit is the "quantum" extra
uv run python .\dotfiles\windows11\tests\smoke-tests\hello_qiskit.py
```

---

## Known pitfalls (so you don't re-hit them)

- **`--locked` Cargo.lock error**: uv/maturin pass `--locked`; the sdist's committed
  lock is stale. Fix = git tag tarball (+ matching pyo3 pin), or delete lock +
  `locked = false`.
- **`link.exe not found`**: means a proc-macro/build-script compiled for the **msvc**
  host. Use the `gnullvm` toolchain as the **host** toolchain (`RUSTUP_TOOLCHAIN`),
  not just as a target.
- **MSVC-ABI wheels vs GNU-ABI build**: this route produces `win_arm64` wheels of
  the **gnullvm/GNU-image** flavour. They load into the UCRT-based CPython 3.13 arm64
  (same CRT Python links). Do **not** mix with `--target aarch64-pc-windows-msvc`
  builds.
- **Don't re-download llvm-mingw**: it's extracted and sha-verified already.
- **Alternative ever-green option**: watch for future rustworkx releases that bump
  pyo3 properly (PR Qiskit/rustworkx#1603 "Bump PyO3 and rust-numpy to latest 0.29")
  — once a release ships with a consistent lock, the whole sdist path just works.

---

## Files that reference this deferral
- `../quantum-win/pyproject.toml` — qiskit moved to a `quantum` OPTIONAL EXTRA; deferral annotations
- `../scripts/install-quantum.ps1` — `-SkipQuantumBuild` / `-IncludeQuantum` escape hatches
- `../scripts/install-build-toolchain.ps1` — resume env
- `../tests/smoke-tests/run-all.ps1` — auto-skips qiskit until installed
- `../MACHINE.md`, `../README.md` — parity table status