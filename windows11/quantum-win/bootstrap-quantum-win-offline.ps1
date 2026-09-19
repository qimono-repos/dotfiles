<#
  quantum-win ARM64 bootstrap (offline-first, idempotent)
  Run from Ghostty/any terminal AFTER a fresh `git clone` of qimono/dotfiles.
  Vendors qiskit+rustworkx win_arm64 wheels (uv would otherwise SOURCE-BUILD them).
  Needs: uv (see winget/uv note in README). Keep wired to offline cache.
#>
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
cd $root

# 1) arch guard
if ([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture -ne 'Arm64') {
  throw "quantum-win requires a Snapdragon X (win_arm64). Found: $([System.Runtime.InteropServices.RuntimeInformation]::ProcessArchitecture)"
}

# 2) uv present?
if (-not (Get-Command uv -EA SilentlyContinue)) {
  Write-Warning "uv not found -> installing via winget (needs ONE internet burst)"
  winget install --id astral-sh.uv -e --accept-source-agreements --accept-package-agreements
  if ($LASTEXITCODE -ne 0) { throw "uv install failed" }
}
"uv version: $(uv --version)"

# 3) sync -- offline wheels first, fall back to cache-hit mode
"uv sync (offline wheels first)..."
$w = Join-Path $root 'wheels'
uv sync --offline --find-links $w
if ($LASTEXITCODE -ne 0) {
  Write-Warning "offline uv sync had a hiccup -> retrying with cache-addressed wheel set"
  uv sync --find-links $w
  if ($LASTEXITCODE -ne 0) { throw "uv sync failed even online" }
}

# 4) THE contract: qiskit imports from the terminal
.\.venv\Scripts\python.exe -c "from qiskit import QuantumCircuit; from qiskit.quantum_info import Statevector; q=QuantumCircuit(3); q.h([0,1,2]); s=Statevector.from_instruction(q); p=s.probabilities_dict(); assert len(p)==8 and abs(sum(p.values())-1)<1e-6; print('QUANTUM READY |', 'qiskit 2.5.2 rustworkx 0.18.1 win_arm64')"
if ($LASTEXITCODE -ne 0) { throw "qiskit import failed" }

"== done. run a python shell with:  .\.venv\Scripts\python.exe  =="