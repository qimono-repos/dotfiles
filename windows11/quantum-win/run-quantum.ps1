<#  run-quantum: repeatable terminal entry into the offline qiskit venv.
    Call from quantum-win:  .\run-quantum.ps1  -> opens a Ghostty-style prompt
    where qiskit already loads. Keeps the git skeleton clean (no .venv commits). #>
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$py = Join-Path $root '.venv\Scripts\python.exe'
if (-not (Test-Path $py)) { throw "no venv yet -> run .\bootstrap-quantum-win-offline.ps1 first" }
Write-Host "quantum-win | qiskit 2.5.2 | offline venv" -ForegroundColor Cyan
& $py
