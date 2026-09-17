# windows11

Machine pack for the **Qimono Windows 11 (Snapdragon / ARM64) host — "Yin"** — the
Windows sibling of the `ubuntu-len-yog-ARM64` Linux pack.

| Field | Value |
|-------|-------|
| Host | Yin (Windows) |
| Hardware | Snapdragon ARM64 laptop (Win11 Home on ARM) |
| OS | Windows 11 Home, build 10.0.26200 |
| Goal | Installed toolchain "as similar as possible" to `ubuntu-len-yog-ARM64` |
| Budget | ~500 MB session budget; bumped to 1 GiB tracked cap mid-run (2026-09-16) |

## Parity table (mirrored from ubuntu-len-yog-ARM64)

| ARM64 Linux item | Windows equivalent | Status here |
|------------------|--------------------|-------------|
| Guix python + uv | Python 3.13 (arm64) + `uv` | ✅ tier-1 |
| neovim · emacs · vscodium | same apps (winget) | ✅ tier-1 |
| ripgrep · fd · fzf | winget | ✅ tier-1 |
| fastfetch (display beats) | winget `Fastfetch-cli.Fastfetch` | ✅ tier-1 |
| oh-my-posh + Catppuccin | winget `JanDeDobbeleer.OhMyPosh` | ✅ tier-1 |
| ghostty (console) | **winghostty** 1.3.123 (community ARM64) | ✅ optional |
| font-nerd-caskaydia | Caskaydia Cove Nerd Font (6 TTFs, per-user) | ✅ optional |
| firefox (snap) | already installed | ok |
| git · gh · bun · ollama | already installed | ok |
| node / nvm | Node 24 LTS (arm64) | ✅ tier-1 |
| openjdk (Guix) | **frozen: Android Studio JBR 25.0.3** — see `../ubuntu/README_JAVA_FOR_MOBILE.md` | untouched |
| quantum workspace (uv) | `quantum-win/` subset — **qiskit 2.5.2 INSTALLED** (source-built; see `doc/BUILD-QUANTUM-WIN_ARM64.md`) | ok |
| Ollama + gemma4:e2b | Ollama installed; model pull = manual (7.2 GB) | deferred |
| .zshrc + .zshrc.d | `$PROFILE` + `Profile.d/` | ✅ setup-profile |
| (bonus) network budget monitor | `scripts/check-network-budget.ps1` — hard 1 GiB received-cap | ✅ new |

## What is deliberately different on Windows ARM64

- **No `qiskit-aer` / `pennylane-lightning`** — no `win_arm64` wheels exist; a
  native install would be an MSVC source build (hours). Documented in
  `quantum-win/pyproject.toml`. The LINUX simulator stack runs 1:1 in WSL2 Ubuntu.
- **`qiskit` 2.5.2 INSTALLED (2026-09-17)** — source-built `win_arm64` (its
  `rustworkx` 0.18.1 dependency was built first with the same toolchain). Build
  record + resume path: `doc/BUILD-QUANTUM-WIN_ARM64.md` /
  `scripts/install-build-toolchain.ps1`.
- **Q# (qdk)** — Python package not guaranteed on win_arm64; Q# remains a
  WSL2/other-host item for now.
- **Ghostty** — official builds are macOS/Linux only; the community ARM64 build
  (winghostty 1.3.123) is used.
- **Package manager ranking (Windows):** 1 **winget** · 2 **uv** · 3 **Store/msix**.
  No Guix here.

## Documentation index

| Doc | Purpose |
|-----|---------|
| [`doc/TOOLCHAIN.md`](doc/TOOLCHAIN.md) | What's installed, where, why (core + build toolchain + exclusions) |
| [`doc/BUILD-QUANTUM-WIN_ARM64.md`](doc/BUILD-QUANTUM-WIN_ARM64.md) | **Build record** for qiskit 2.5.2 / rustworkx 0.18.1 source build (2026-09-17) |
| [`doc/NETWORK-BUDGET.md`](doc/NETWORK-BUDGET.md) | The 1 GiB received-cap monitor: how it works, usage, caveats |
| [`doc/TROUBLESHOOTING.md`](doc/TROUBLESHOOTING.md) | Real failures hit during provisioning + fixes |

## Quick start (this machine)

```powershell
cd dotfiles/windows11
.\scripts\install-core.ps1            # tier-1 winget batch (+node, emacs)
.\scripts\install-uv-python.ps1       # real python + uv + UV_PYTHON policy
.\scripts\setup-profile.ps1           # $PROFILE + Profile.d snippets
.\scripts\install-quantum.ps1         # uv sync quantum-win spec -> quantum-workspace
                                     # (-SkipQuantumBuild to only prep docs/scripts)
.\scripts\install-build-toolchain.ps1 # resume env for qiskit (see doc)
.\scripts\check-network-budget.ps1    # audit/hard-stop received bytes
```

Verify:

```powershell
rg --version ; fd --version ; fzf --version ; fastfetch --version
nvim --version | Select-Object -First 1
emacs --version | Select-Object -First 1
node --version ; python --version ; uv --version
$env:PATH -split ';' | Where-Object { $_ -match 'winghostty' }
pwsh .\scripts\check-network-budget.ps1
```

QA checklists (Human + AI) live in [`QA/`](./QA/).

