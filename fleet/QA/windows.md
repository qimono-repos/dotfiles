# QA — fleet bootstrap, Windows (PowerShell, no WSL)

Scope: `irm https://qimono.online/install.ps1 | iex`.
Human + AI checklists (via the AI-listed commands, run in PowerShell).

## Pre-flight (fresh Windows)

- [ ] Windows 10 1809+ or Windows 11 (winget / App Installer available)
- [ ] winget: `winget --version` (else install App Installer from Microsoft Store)
- [ ] PowerShell 5.1+ (Windows PowerShell is fine; PowerShell 7 recommended)

## Windows run

- [ ] `set-ExecutionPolicy -Scope CurrentUser RemoteSigned` applied
- [ ] TLS 1.2+ enabled for `Invoke-WebRequest`
- [ ] Entrypoint downloads fleet kit to `%USERPROFILE%\.qimono\fleet`
- [ ] `winget.ps1` runs `winget import` on `fleet/winget.json`
- [ ] Git, Windows Terminal, Bun, opencode installed via winget
- [ ] Dotfiles cloned to `%USERPROFILE%\source\repos\qimono-repos\dotfiles`

## Post-run verify (AI can run automatically, in PowerShell)

- [ ] `(Get-Command winget).Source` present
- [ ] `winget list --exact -q Git.Git`
- [ ] `winget list --exact -q Microsoft.WindowsTerminal`
- [ ] `winget list --exact -q Oven-sh.Bun`
- [ ] `winget list --exact -q SST.opencode`
- [ ] `Test-Path "$env:USERPROFILE\source\repos\qimono-repos\dotfiles\.git"`

## Known traps

- **No WSL / full PowerShell:** this path never shells into WSL; all tooling is
  native Windows. Terminal TUI apps may need Windows Terminal (re-tested).
- **winget package IDs change** — `SST.opencode` is the CLI; `SST.OpenCodeDesktop`
  is the desktop app. The import uses the CLI only.
- **Execution policy** blocks unsigned scripts by default; script sets
  `CurrentUser RemoteSigned`, which is the least-privilege usable setting.
- **repo is public:** clone over HTTPS needs no GitHub auth on a fresh box.
