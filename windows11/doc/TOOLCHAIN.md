# Windows11 (ARM64) Toolchain Map

Companion to `MACHINE.md`. This file maps **what is installed where** on Yin, the
Snapdragon X Windows 11 Home ARM64 machine, and why. Generated 2026-09-16.

> Budget context: this machine pack mirrors `ubuntu-len-yog-ARM64/` but everything
> was installed under a ~500 MB (then 1 GiB) download budget. Bold rows were the
> non-negotiable core; everything else was prioritized explicitly.

---

## Core (install-core.ps1)

| Tool | Version | Provider | Real path |
|---|---|---|---|
| ripgrep | 15.2.0 (arm64) | winget `BurntSushi.ripgrep.MSVC` | `~\.cargo\bin\rg.exe` or `%LOCALAPPDATA%\Microsoft\WinGet\Links\rg.exe` |
| fd | 10.5.0 (arm64) | winget `sharkdp.fd` | `%LOCALAPPDATA%\Microsoft\WinGet\Links\fd.exe` |
| fzf | 0.74.4 (arm64) | winget `junegunn.fzf` | `%LOCALAPPDATA%\Microsoft\WinGet\Links\fzf.exe` |
| fastfetch | 2.68.1 | winget `Fastfetch-cli.Fastfetch` | `%LOCALAPPDATA%\Microsoft\WinGet\Links\fastfetch.exe` |
| Neovim | latest (win32arm64) | winget `Neovim.Neovim` | `%LOCALAPPDATA%\Programs\Neovim\bin\nvim.exe` |
| oh-my-posh | latest | winget `JanDeDobbeleer.OhMyPosh` | `%LOCALAPPDATA%\Microsoft\WinGet\Links\oh-my-posh.exe` |
| Python 3.13 (arm64) | 3.13.x | winget `Python.Python.3.13` (arm64) | `C:\Users\qi\AppData\Local\Programs\Python\Python313-arm64\python.exe` |
| uv | 0.12.15 (arm64) | winget `astral-sh.uv` | `%LOCALAPPDATA%\Microsoft\WinGet\Links\uv.exe` |
| Node.js LTS | latest | winget `OpenJS.NodeJS.LTS` | `%LOCALAPPDATA%\Programs\nodejs\node.exe` |
| Emacs | 31.1 | winget `GNU.Emacs` (or installer) | `C:\Program Files\Emacs\emacs-31.1\bin\emacs.exe` |

### Python/uv policy
- Windows App Execution Aliases stub `python` (Store entry); the **real** CPython
  is pinned via `UV_PYTHON` (set by `install-uv-python.ps1`).
- Policy env: `UV_PYTHON_PREFERENCE=only-system`, `UV_PYTHON_DOWNLOADS=never`,
  `UV_PYTHON=<real->.exe>`, `QIMONO_WIN_PYTHON=<real->.exe>` (all User-scope).

---

## Terminal & fonts (installed after core)

| Item | Detail |
|---|---|
| Ghostty | community fork **winghostty** 1.3.123, ARM64 portable → `C:\Users\qi\Tools\winghostty\winghostty\` (sha256 verified), added to user PATH |
| Caskaydia Cove Nerd Font | v3.5.1, 6 TTFs (Regular/Bold/Italic × Mono/Regular) → per-user fonts, no admin |

---

## Shell (setup-profile.ps1)

- `Microsoft.PowerShell_profile.ps1` + 8 snippets in `Profile.d/{00,15,20,25,30,40,42,50}`,
  installed into `$PROFILE` dir (`OneDrive\Documents\PowerShell`).

---

## Build toolchain (reserved — see BUILD-QUANTUM-WIN_ARM64.md)

| Component | Installed? | Location |
|---|---|---|
| RustUP 1.29.1 | ✅ | winget → `~\.rustup\bin\rustup.exe` (also `~\.cargo\bin`) |
| Rust stable **msvc** aarch64 1.98.1 | ✅ | `~\.rustup\toolchains\stable-aarch64-pc-windows-msvc` |
| Rust stable **gnullvm** aarch64 1.98.1 | ✅ | `~\.rustup\toolchains\stable-aarch64-pc-windows-gnullvm` (default linker `rust-lld`) |
| llvm-mingw 20260908 (ucrt-aarch64) | ✅ | `C:\Users\qi\Tools\llvm-mingw\` (177 MB zip, sha `7fe35f60…`) |
| Zig 0.16.0 | ✅ | winget `zig.zig` (explored as linker; superseded by gnullvm/rust-lld) |
| maturin 1.15.0 | ✅ | quantum-workspace `.venv` |

Why this stack instead of Visual Studio: VS Build Tools is 1–2 GB and the machine
has none. `aarch64-pc-windows-gnullvm` + llvm-mingw clang compiles & links UCRT
modules for CPython 3.13 arm64 with no MSVC at all. **This is the resume path for
qiskit** — it was validated end-to-end with a tiny cdylib before deferring.

**Java: FROZEN** — do not install/replace. Reference = Android Studio bundled JBR
OpenJDK 25.0.3 at `C:\Program Files\Android\Android Studio\jbr` (`JAVA_HOME`).
See `ubuntu/README_JAVA_FOR_MOBILE.md` for the Linux alignment notes.

---

## Preexisting (NOT reinstalled by this pack)

git, gh, pwsh, bun, ollama (no models), VSCodium/VS Code, Windows Terminal,
Podman Desktop, tree, tig.

## Deliberately absent / excluded

- `qiskit` 2.5.2, `rustworkx` 0.18.1 — **installed 2026-09-17** via llvm-mingw gnullvm source build (see `doc/BUILD-QUANTUM-WIN_ARM64.md`)
- `qiskit-aer` — no `win_arm64` wheels at all (CI ships only x64 + Linux aarch64)
- `qdk` (Q#) — win_arm64 availability not guaranteed
- `pennylane` — hard-depends on `rustworkx`; same wheel gap

## Resetting / diagnosing

- Python stub shadowing `python`: re-pin via `install-uv-python.ps1`
- uv refusing python: check `UV_PYTHON_PREFERENCE`/`UV_PYTHON_DOWNLOADS` are set
- Monitor reset: `check-network-budget.ps1 -Reset`
- Full toolchain re-provisioning: `install-build-toolchain.ps1` (idempotent)


