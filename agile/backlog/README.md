# Agile Backlog — Cross-Platform Developer Environment

Welcome to the Agile backlog for the **Cross-Platform Neovim (LazyVim) + Oh My Posh (Catppuccin) + Cascaydia Cove (Nerd Font)** environment rollout across Qimono infrastructure.

---

## Repository Backlog Structure

```text
agile/backlog/
├── README.md                                    # Backlog index and roadmap
├── FEASIBILITY-ESTIMATION-MATRIX.md             # Platform feasibility & story point estimation
└── EPIC-01-cross-platform-shell-editor-environment.md # User stories & acceptance criteria
```

---

## Targeted Platform Matrix Summary

| Platform ID | Environment Description | Primary Package Manager | Agile Story Points | Feasibility | Status |
|---|---|---|---|---|---|
| **PLAT-01** | Linux Ubuntu x86_64 / Intel | GNU Guix + apt | 3 SP | High (9.5/10) | **Implemented & Verified** |
| **PLAT-02** | Linux Ubuntu ARM64 (Snapdragon / Pi 4) | GNU Guix (`aarch64`) + apt | 5 SP | High (8.5/10) | Planned |
| **PLAT-03** | macOS Apple Silicon (Golden Gate) + Ghostty | Homebrew (Safety Net) + Guix Darwin | 5 SP | High (9.0/10) | Planned |
| **PLAT-04** | Asahi Linux on Apple Silicon (M5+) | GNU Guix System | 13 SP | Medium (6.0/10) | Planned |
| **PLAT-05** | Windows 11 Native (No WSL) | Winget + PowerShell 7+ | 8 SP | Med-High (8.0/10) | In Progress (Scripts in `windows11/`) |

---

## Total Epic Estimate
* **Total Velocity Required**: 34 Story Points
* **Sprint Capacity (Recommended)**: 10–13 Story Points per 2-week sprint
* **Estimated Delivery**: 3 Sprints
