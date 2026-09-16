# Filename: install-quantum.ps1
# Description: Materialise the win_arm64 quantum uv workspace from the pinned
#   spec in this pack (quantum-win/pyproject.toml) into
#   ${QIMONO_QUANTUM_HOME:-$HOME\source\repos\qimono-repos\quantum-workspace},
#   then `uv sync` and register a Jupyter kernel named "quantum".
#
# Non-destructive, mirrors install-quantum-python.sh from the ARM64 pack.
#
# qiskit is DEFERRED on win_arm64 (2026-09-16): no win_arm64 wheel + rustworkx's
# stale Cargo.lock. The base spec resolves cleanly (numpy/matplotlib/jupyterlab/
# notebook/ipykernel). qiskit is an OPTIONAL EXTRA ("quantum") that is only
# attempted when -IncludeQuantum is passed — do that after following
# doc/BUILD-QUANTUM-WIN_ARM64.md (rustup gnullvm + llvm-mingw + pyo3 pin).
#
# Flags:
#   -SkipQuantumBuild : do not touch the workspace at all (docs/scripts only).
#   -IncludeQuantum   : ALSO try the "quantum" extra (qiskit) — resume path;
#                       requires the build toolchain (install-build-toolchain.ps1).

param(
    [switch]$SkipQuantumBuild,
    [switch]$IncludeQuantum
)

$ErrorActionPreference = 'Stop'

$ROOT   = Split-Path -Parent $PSScriptRoot
$SPEC   = Join-Path $ROOT 'quantum-win'
$WS     = if ($env:QIMONO_QUANTUM_HOME) { $env:QIMONO_QUANTUM_HOME } else { Join-Path $HOME 'source\repos\qimono-repos\quantum-workspace' }

if (-not (Test-Path (Join-Path $SPEC 'pyproject.toml'))) {
    Write-Error "quantum spec missing: $SPEC\pyproject.toml"; exit 1
}
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Error 'uv not on PATH — run install-core.ps1 + install-uv-python.ps1 first'; exit 1
}

if ($SkipQuantumBuild) {
    Write-Host '==> -SkipQuantumBuild: leaving workspace untouched.
    Current quantum status: qiskit DEFERRED (bandwidth) — see doc/BUILD-QUANTUM-WIN_ARM64.md' -ForegroundColor Yellow
    exit 0
}

# Re-assert policy (env may not have persisted into this elevated session)
$env:UV_PYTHON_PREFERENCE = 'only-system'
$env:UV_PYTHON_DOWNLOADS  = 'never'
if ($env:UV_PYTHON -and -not (Test-Path $env:UV_PYTHON)) { Remove-Item Env:UV_PYTHON }

Write-Host "==> workspace: $WS" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $WS | Out-Null

# Place the pinned spec (never overwrite a hand-tuned pyproject)
$dstPy = Join-Path $WS 'pyproject.toml'
if (Test-Path $dstPy) {
    if (-not (Select-String -Path $dstPy -Pattern 'name = "quantum-workspace-win"')) {
        Write-Error "Refusing to overwrite $dstPy (not the quantum-workspace-win spec)."; exit 1
    }
    Write-Host '==> existing spec present, keeping it' -ForegroundColor DarkGray
} else {
    Copy-Item (Join-Path $SPEC 'pyproject.toml') $dstPy
}
# NOTE: do NOT copy quantum-win/uv.lock — there is none (removed 2026-09-16; the
# retired lock pre-dated the qiskit-extra move). Always re-lock for win_arm64.

Push-Location $WS
try {
    Write-Host '==> uv lock (fresh resolution for win_arm64)' -ForegroundColor Yellow
    if ($IncludeQuantum) {
        uv lock --extra quantum
    } else {
        uv lock
    }
    if ($LASTEXITCODE -ne 0) { Write-Error 'uv lock failed'; exit 1 }

    Write-Host '==> uv sync (exact versions)' -ForegroundColor Yellow
    if ($IncludeQuantum) {
        uv sync --extra quantum --extra dev
    } else {
        uv sync --extra dev
    }
    if ($LASTEXITCODE -ne 0) { Write-Error 'uv sync failed'; exit 1 }

    Write-Host '==> registering Jupyter kernel "quantum"' -ForegroundColor Yellow
    uv run python -m ipykernel install --user --name=quantum --display-name 'Python (quantum)'

    $quantumNote = if ($IncludeQuantum) { '' } else { '  (qiskit NOT installed — run with -IncludeQuantum after doc/BUILD-QUANTUM-WIN_ARM64.md resume steps)' }
    Write-Host "`nOK: quantum env ready at $WS$quantumNote" -ForegroundColor Green
    Write-Host "    cd $WS ; uv run jupyter lab --no-browser --port=5005"
} finally {
    Pop-Location
}