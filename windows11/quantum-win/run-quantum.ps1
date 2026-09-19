<#  run-quantum: quantum terminal REPL via uv (project-scoped, offline-capable).
    Compare:  uv :: python  ==  npx :: node.  No `activate` needed, ever.
    The venv python under .\.venv\Scripts\ only exists for uv's engine; you
    always enter through `uv run`. #>
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

if (-not (Test-Path .\.venv)) {
    Write-Host "no .venv yet -> bootstrap first (vendored arm64 wheels, offline)" -ForegroundColor Yellow
    & .\bootstrap-quantum-win-offline.ps1
    if ($LASTEXITCODE -ne 0) { throw "bootstrap failed -> see doc/BUILD-QUANTUM-WIN_ARM64.md" }
}

Write-Host "quantum-win | uv run terminal | qiskit 2.5.2 | rustworkx 0.18.1 | win_arm64" -ForegroundColor Cyan
uv run python
