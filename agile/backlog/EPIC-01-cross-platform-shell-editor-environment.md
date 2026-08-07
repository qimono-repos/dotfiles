# EPIC-01: Cross-Platform Universal Shell & Editor Environment

**Epic Description**: Establish a seamless, reproducible, cross-platform developer environment featuring **Neovim (LazyVim)**, **Oh My Posh (Catppuccin theme)**, **Cascaydia Cove Nerd Font**, and **GNU Stow / PowerShell profile management** across Linux (x86_64 & ARM64), macOS, Asahi Linux, and Windows 11 Native.

---

## Feature 1: Linux Ubuntu (AMD64 & ARM64) Guix Integration

### User Story 1.1: Automated Font & Prompt Installer on Ubuntu x86_64
* **Statement**: As a developer, I need an automated installer script that downloads the Caskaydia Cove Nerd Font and Oh My Posh via `curl` and configures the Catppuccin theme, so that my shell prompt renders with rich iconography out of the box on fresh Ubuntu AMD64 installs.
* **Acceptance Criteria**:
  - Script installs `oh-my-posh` into `~/.local/bin`.
  - Downloads and registers `CascadiaCode.zip` in `~/.local/share/fonts/NerdFonts`.
  - Applies Stow symlinks for `.zshrc` and `.config/oh-my-posh/catppuccin.omp.json`.
  - Non-destructive backup created if `~/.zshrc` already exists.
* **Estimate**: 3 Story Points

### User Story 1.2: ARM64 Ubuntu Adaptation (Raspberry Pi 4 & Snapdragon)
* **Statement**: As a developer, I need GNU Guix and Stow scripts optimized for ARM64 Linux architectures, so that I can maintain identical prompt, zsh, and Neovim behavior on Snapdragon laptops and Raspberry Pi 4 nodes.
* **Acceptance Criteria**:
  - Shell initialization scripts detect `aarch64` architecture dynamically.
  - Guix profile sources appropriate binary substitutes (`ci.guix.gnu.org` / `bordeaux.guix.gnu.org`).
  - Treesitter parsers compile cleanly on ARM64 Neovim.
* **Estimate**: 5 Story Points

---

## Feature 2: macOS (Golden Gate M-Series) Homebrew & Ghostty Integration

### User Story 2.1: macOS Environment & Ghostty Terminal Configuration
* **Statement**: As a developer, I need macOS-compatible Stow rules and Homebrew safety nets for Oh My Posh, Neovim, and Guix Darwin, so that I can use the exact same dotfiles configuration inside Ghostty and xterm on Apple Silicon.
* **Acceptance Criteria**:
  - `stow` links configs correctly relative to `/Users/$USER`.
  - Homebrew acts as a unified safety net for Neovim, Oh My Posh, fonts, Node, and Python alongside Guix Darwin.
  - Ghostty terminal settings configure Caskaydia Cove Nerd Font and 24-bit color seamlessly.
* **Estimate**: 5 Story Points

---

## Feature 3: Asahi Linux on Apple Silicon (M5+) Guix System Setup

### User Story 3.1: Asahi Linux Kernel Driver & Guix Manifest Integration
* **Statement**: As a developer, I need Guix package manifests and shell configurations tailored for Asahi Linux on M-series hardware, so that I can run a fully free-software developer environment with hardware-accelerated Neovim and Oh My Posh.
* **Acceptance Criteria**:
  - Manifest includes `gcc-toolchain`, `ripgrep`, `fd`, `neovim`, and `stow` compiled for Asahi Linux kernel interfaces.
  - Oh My Posh initializes seamlessly without shell startup latency.
* **Estimate**: 13 Story Points

---

## Feature 4: Windows 11 Native (No WSL) PowerShell Automation

### User Story 4.1: PowerShell 7+ Profile Stowing & Winget Bootstrapping
* **Statement**: As a developer, I need a native PowerShell setup script (`install-oh-my-posh.ps1`) using Winget and PowerShell `$PROFILE` symlinking, so that I get the exact same Neovim, Oh My Posh Catppuccin theme, and Cascaydia Cove font experience on Windows 11 without relying on WSL.
* **Acceptance Criteria**:
  - `install-oh-my-posh.ps1` checks for Administrator privileges and uses `winget` to install `JanDeDobbeleer.OhMyPosh`, `Git.Git`, and `Neovim.Neovim`.
  - Font `CaskaydiaCove` is installed via PowerShell `curl` / `Invoke-WebRequest` into `C:\Windows\Fonts` or User Fonts directory.
  - PowerShell `$PROFILE` is linked to `windows11/powershell/Microsoft.PowerShell_profile.ps1` via `New-Item -ItemType SymbolicLink`.
  - `oh-my-posh init pwsh --config $HOME\.config\oh-my-posh\catppuccin.omp.json` executes on PowerShell launch.
* **Estimate**: 8 Story Points
