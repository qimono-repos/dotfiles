<#
.Qimono fleet bootstrap — Windows PowerShell entrypoint (irm | iex).

Usage (PowerShell, no WSL):
  irm https://qimono.online/install.ps1 | iex
  # raw pre-DNS:
  irm https://raw.githubusercontent.com/qimono-repos/dotfiles/main/fleet/install.ps1 | iex

Only Windows uses this path; Linux/macOS use fleet/install (curl | sh).
This is deliberately THIN: it downloads the fleet kit tarball, extracts it
to $HOME\.qimono\fleet, and runs winget.ps1.
#>
$ErrorActionPreference = 'Stop'

$Repo     = 'qimono-repos/dotfiles'
$Branch   = 'main'
$Tarball  = "https://github.com/$Repo/archive/refs/heads/$Branch.tar.gz"
$KitDir   = Join-Path $HOME '.qimono\fleet'

Write-Host "=== qimono fleet bootstrap (Windows) ===" -ForegroundColor Cyan

$KitTemp = Join-Path $env:TEMP 'qimono-fleet-kit'
if (Test-Path $KitTemp) { Remove-Item $KitTemp -Recurse -Force }
New-Item -ItemType Directory -Path $KitTemp -Force | Out-Null

Write-Host "--- fetching fleet kit ---"
Invoke-WebRequest -Uri $Tarball -OutFile (Join-Path $KitTemp 'fleet.tar.gz') -UseBasicParsing
tar -xzf (Join-Path $KitTemp 'fleet.tar.gz') -C $KitTemp

$Pkg = Get-ChildItem $KitTemp -Directory | Where-Object { $_.Name -like 'dotfiles-*' } | Select-Object -First 1
if (-not $Pkg -or -not (Test-Path (Join-Path $Pkg.FullName 'fleet'))) {
    throw 'Fleet kit did not contain an expected fleet/ directory.'
}

New-Item -ItemType Directory -Path $KitDir -Force | Out-Null
Copy-Item (Join-Path $Pkg.FullName 'fleet\*') $KitDir -Recurse -Force
Write-Host "--- fleet kit -> $KitDir ---"

Write-Host "--- running winget bootstrap ---" -ForegroundColor Cyan
& (Join-Path $KitDir 'winget.ps1')
Write-Host "=== done. Restart your terminal. ===" -ForegroundColor Green
