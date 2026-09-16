# Filename: install-uv-python.ps1
# Description: Ensure a REAL CPython + uv are available and set the uv Python
#   policy env vars (mirror of the ARM64 pack's 20-uv-python.zsh).
#
# Python policy (Windows edition of 20-uv-python.zsh):
#   * uv must NEVER download its own CPython.
#   * uv must use the machine/system interpreter only.
#   * UV_PYTHON is pinned to the real python.org interpreter (NOT the
#     WindowsApps MSIX stub, which resolves to the Store or nothing in some
#     shells).
#
# Idempotent. Requires install.ps1/core to have put python + uv on PATH.

$ErrorActionPreference = 'Stop'

function Set-UserEnv([string]$name, [string]$value) {
    [Environment]::SetEnvironmentVariable($name, $value, 'User')
    Set-Item -Path "Env:$name" -Value $value
    "env $name = $value"
}

# --- 1) find the REAL python (python.org), not the WindowsApps MSIX stub ---
$py = $null
foreach ($candidate in @(
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python313-arm64\python.exe"
)) {
    if (Test-Path $candidate) { $py = $candidate; break }
}
if (-not $py) {
    $cmd = Get-Command python -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source -notlike '*WindowsApps*') { $py = $cmd.Source }
}
if (-not $py) { Write-Error 'real python.org build not found — install Python.Python.3.13 first'; exit 1 }
Write-Host "python (real build): $py" -ForegroundColor Cyan

# --- 2) uv (winget installs into %LOCALAPPDATA%\Microsoft\WinGet\Links) ---
$uvExe = $null
$uvCmd = Get-Command uv -ErrorAction SilentlyContinue
if ($uvCmd) { $uvExe = $uvCmd.Source }
if (-not $uvExe) {
    $wingetUv = "$env:LOCALAPPDATA\Microsoft\WinGet\Links\uv.exe"
    if (Test-Path $wingetUv) { $uvExe = $wingetUv } else { Write-Error 'uv not found on PATH after tier-1 install'; exit 1 }
}
$env:PATH = "$env:LOCALAPPDATA\Microsoft\WinGet\Links;$env:PATH"
"uv: $uvExe  $(& $uvExe --version)"

# --- 3) policy (persisted for the user + set for this session) ----------
Set-UserEnv 'UV_PYTHON_PREFERENCE' 'only-system'
Set-UserEnv 'UV_PYTHON_DOWNLOADS'  'never'
Set-UserEnv 'UV_PYTHON'            $py

# Convenience marker mirroring QIMONO_GUIX_PYTHON
Set-UserEnv 'QIMONO_WIN_PYTHON'    $py

Write-Host "`nOK: uv pinned to $py" -ForegroundColor Green
Write-Host 'New shells will honor only-system / never-download policy.'