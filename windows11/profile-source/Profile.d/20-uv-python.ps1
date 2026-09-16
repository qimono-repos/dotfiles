# 20-uv-python.ps1 — Python policy (Windows edition of 20-uv-python.zsh).
#
# * uv must NEVER download its own CPython.
# * uv uses the machine interpreter ONLY (the real python.org build, pinned by
#   install-uv-python.ps1); the WindowsApps MSIX stub is never used for dev.
# * QIMONO_QUANTUM_HOME + qimono-quantum alias mirror the Linux pack.

$env:UV_PYTHON_PREFERENCE = 'only-system'
$env:UV_PYTHON_DOWNLOADS  = 'never'
if ($env:UV_PYTHON -and -not (Test-Path $env:UV_PYTHON)) {
    Remove-Item Env:UV_PYTHON
    Write-Warning '20-uv-python: UV_PYTHON pointed at a missing file; cleared. Run install-uv-python.ps1 to re-pin.'
}

$env:QIMONO_QUANTUM_HOME = if ($env:QIMONO_QUANTUM_HOME) { $env:QIMONO_QUANTUM_HOME } else {
    Join-Path $HOME 'source\repos\qimono-repos\quantum-workspace'
}
function qimono-quantum { Set-Location $env:QIMONO_QUANTUM_HOME }
Set-Alias -Name qq -Value qimono-quantum -Scope Global