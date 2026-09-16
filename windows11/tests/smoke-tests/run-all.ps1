# Filename: run-all.ps1
# Description: Run quantum hello smokes inside the quantum workspace env.
#   Usage (from quantum-workspace): uv run pwsh <pack>\tests\smoke-tests\run-all.ps1
#   or with QIMONO_QUANTUM_HOME set.
#
#   qiskit is DEFERRED on win_arm64 (bandwidth decision 2026-09-16) — see
#   windows11/doc/BUILD-QUANTUM-WIN_ARM64.md. By default only tests whose deps
#   are actually installed in the workspace run; -IncludePennylane forces the
#   pennylane smoke (pennylane is not part of the win spec).

param(
    [switch]$IncludePennylane
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = 'Stop'
$ws = if ($env:QIMONO_QUANTUM_HOME) { $env:QIMONO_QUANTUM_HOME } else { Join-Path $HOME 'source\repos\qimono-repos\quantum-workspace' }
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path (Join-Path $ws 'pyproject.toml'))) { Write-Error "quantum workspace missing: $ws"; exit 1 }

# Detect which libraries the workspace env actually has installed.
$py = Join-Path $ws '.venv\Scripts\python.exe'
function Has-Module([string]$name) {
    if (-not (Test-Path $py)) { return $false }
    & $py -c "import $name" 2>$null
    return ($LASTEXITCODE -eq 0)
}

$tests = @()
if (Has-Module qiskit) { $tests += 'hello_qiskit.py' }
if ($IncludePennylane -and (Has-Module pennylane)) { $tests += 'hello_pennylane.py' }
if ($tests.Count -eq 0) {
    Write-Host 'No quantum deps installed in workspace (qiskit deferred?). Install them first:' -ForegroundColor Yellow
    Write-Host '  see windows11/doc/BUILD-QUANTUM-WIN_ARM64.md for the resume path.' -ForegroundColor Yellow
    exit 0
}

$status = 0
foreach ($t in $tests) {
    Write-Host "--- $t ---"
    Push-Location $ws
    try {
        uv run python (Join-Path $dir $t)
        if ($LASTEXITCODE -ne 0) { $status = 1 }
    } catch { Write-Host "  -> threw: $($_.Exception.Message)" -ForegroundColor Red; $status = 1 }
    finally { Pop-Location }
}

if ($status -eq 0) { Write-Host 'ALL OK' -ForegroundColor Green } else { Write-Host 'SOME FAILED' -ForegroundColor Red; exit 1 }