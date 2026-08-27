<#
.Qimono fleet bootstrap — Windows (no WSL): winget import + clone + link.

Flows (all idempotent):
  1. Ensure TLS 1.2 and a permissive-enough ExecutionPolicy for this user.
  2. Ensure winget (Microsoft.DesktopAppInstaller) present; else guide to the
     Store — no external sudo needed for a personal Windows box.
  3. winget import fleet/winget.json -> installs git, Windows Terminal,
     Bun, opencode.
  4. Clone the PUBLIC dotfiles repo over HTTPS to %USERPROFILE%\source\... .

Run via install.ps1 (irm | iex) on Windows.
#>
$ErrorActionPreference = 'Stop'

# ---- 1. TLS + execution policy -------------------------------------------------
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$NeedPolicy = (Get-ExecutionPolicy -Scope CurrentUser) -notin @('RemoteSigned', 'Unrestricted', 'Bypass')
if ($NeedPolicy) {
    Write-Host '--- setting CurrentUser ExecutionPolicy to RemoteSigned ---'
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
}
Write-Host ('ExecutionPolicy (CurrentUser): ' + (Get-ExecutionPolicy -Scope CurrentUser))

# ---- 2. winget ------------------------------------------------------------------
Write-Host '--- checking winget ---'
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "winget not found. Install 'App Installer' from the Microsoft Store:" -ForegroundColor Yellow
    Write-Host '  https://apps.microsoft.com/detail/9nblggh4nns1'
    Write-Host 'then re-run this bootstrap.'
    exit 2
}
Write-Host ('winget: ' + (winget --version))

# ---- 3. winget import (git, Windows Terminal, bun, opencode) --------------
# Prefer $PSScriptRoot (real file); fall back to the kit dir so `irm|iex`
# standalone usage still finds winget.json.
if ([string]::IsNullOrEmpty($PSScriptRoot)) {
    $Base = Join-Path $HOME '.qimono\fleet'
} else {
    $Base = $PSScriptRoot
}
$WingetJson = Join-Path $Base 'winget.json'
if (-not (Test-Path $WingetJson)) { throw "winget.json not found next to winget.ps1: $WingetJson" }

Write-Host '--- winget import ---'
winget import --import-file $WingetJson --accept-package-agreements --accept-source-agreements --disable-interactivity
if ($LASTEXITCODE -ne 0) {
    Write-Host 'winget import had non-zero exit; review output above.' -ForegroundColor Yellow
}

# ---- 4. clone the public dotfiles repo (HTTPS) ----------------------------------
$QimoSrc = Join-Path $env:USERPROFILE 'source\repos\qimono-repos'
$RepoDir = Join-Path $QimoSrc 'dotfiles'
New-Item -ItemType Directory -Path $QimoSrc -Force | Out-Null

if (Test-Path (Join-Path $RepoDir '.git')) {
    Write-Host "--- dotfiles repo already present: $RepoDir ---"
    git -C $RepoDir pull --ff-only
} else {
    Write-Host '--- cloning dotfiles (public, HTTPS) ---'
    git clone https://github.com/qimono-repos/dotfiles.git $RepoDir
}
Write-Host '--- dotfiles repo ready ---'

Write-Host ''
Write-Host 'Next: open the Qimono fleet README for per-app config + SSH key setup.' -ForegroundColor Green
