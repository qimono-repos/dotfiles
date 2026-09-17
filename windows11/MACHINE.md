# MACHINE.md — Windows 11 Snapdragon ("Yin", windows11 pack)

Snapshot of the host this pack targets. Refresh after major hardware/OS changes.

**Captured:** 2026-09-16 (session bootstrap). **Last verified:** 2026-09-16 (post-toolchain).

## Hardware / OS

| Item | Detail |
|------|--------|
| OS | Microsoft Windows 11 Home (ARM64) — build 10.0.26200 |
| ISA | arm64 (Snapdragon) |
| Shell | PowerShell 7 (pwsh) |
| Python | real CPython 3.13 arm64 → `C:\Users\qi\AppData\Local\Programs\Python\Python313-arm64\python.exe` (`UV_PYTHON` pinned) |
| Package manager | winget (rank 1) · uv (rank 2) |

## Java / mobile toolchain (FROZEN — do not alter)

| Item | Detail |
|------|--------|
| Java runtime | Android Studio bundled JBR → **OpenJDK 25.0.3** (build 25.0.3+-15898627-b508.16) |
| `JAVA_HOME` | `C:\Program Files\Android\Android Studio\jbr` |
| Temurin / other JDK | **none installed — keep it that way** |
| Android SDK | `%LOCALAPPDATA%\Android\Sdk` (platform-tools/adb, build-tools, emulator, cmdline-tools present) |
| Policy | Java/OpenJDK/Temurin are untouched; this machine is the **reference** for the Linux Java alignment doc: [`../ubuntu/README_JAVA_FOR_MOBILE.md`](../ubuntu/README_JAVA_FOR_MOBILE.md) |

## Package manager ranking (Windows)

1. **winget** · 2. **uv** (Python envs) · 3. **Store/msix**

## Installed by this pack (2026-09-16)

- **tier-1 (install-core.ps1):** ripgrep 15.2.0 · fd 10.5.0 · fzf 0.74.4 · fastfetch 2.68.1 ·
  Neovim · oh-my-posh · Python 3.13 (arm64) · uv 0.12.15 · Node 24 LTS · Emacs 31.1.
- **terminal/fonts:** winghostty 1.3.123 (ARM64 portable, `Tools\winghostty\`), Caskaydia Cove
  Nerd Font 3.5.1 (6 TTFs, per-user).
- **shell:** `$PROFILE` + 8× `Profile.d/` snippets.
- **build toolchain (reserved for quantum resume):** RustUP 1.29.1, Rust 1.98.1
  `stable-aarch64-pc-windows-msvc` **and** `stable-aarch64-pc-windows-gnullvm`,
  llvm-mingw 20260908 ucrt-aarch64 (`Tools\llvm-mingw`, sha verified), Zig 0.16.0
  (superseded as linker), maturin 1.15.0 (in quantum-workspace `.venv`).
  → full map: [`doc/TOOLCHAIN.md`](doc/TOOLCHAIN.md).

## Preexisting software (not reinstalled by this pack)

Git (2.55+), GitHub CLI, Bun, Ollama (0.33.x), VSCodium + VS Code, Podman
Desktop (CLI needs explicit init), Windows Terminal (+Preview), WSL2 (no distro
installed), tree, tig.

## Deferred / excluded (with pointers)

| Item | Status | Doc |
|------|--------|-----|
| qiskit (Qiskit only) | **INSTALLED** — source-built win_arm64 (llvm-mingw gnullvm) 2026-09-17 | [`doc/BUILD-QUANTUM-WIN_ARM64.md`](doc/BUILD-QUANTUM-WIN_ARM64.md) |
| pennylane | excluded from spec (hard-depends rustworkx → same wheel gap) | `quantum-win/pyproject.toml` |
| qiskit-aer | excluded (no win_arm64 wheels at all) | `quantum-win/pyproject.toml` |
| qdk (Q#) | excluded (win_arm64 availability not guaranteed) | `quantum-win/pyproject.toml` |
| Ollama model pull | deferred (manual, ~7.2 GB) | — |

## Refresh commands

```powershell
Get-CimInstance Win32_OperatingSystem | Select Caption,Version,OSArchitecture
& "$env:JAVA_HOME\bin\java.exe" -version
winget list | Select-String -Pattern 'Neovim|Emacs|git|Python|Node|uv|OhMyPosh|ripgrep|fastfetch|Zig|Rustup'
where.exe rg fd fzf nvim emacs node python uv fastfetch oh-my-posh
pwsh .\scripts\check-network-budget.ps1
Get-ChildItem "$env:USERPROFILE\.rustup\toolchains" | Select-Object -ExpandProperty Name

