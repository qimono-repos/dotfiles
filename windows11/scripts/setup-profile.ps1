# Filename: setup-profile.ps1
# Description: Install the windows11 pack profile + numbered snippets into the
#   live $PROFILE directory (the "stow analog" for Windows). Idempotent.
#
# Mirrors: stow-apply.sh  →  copies Microsoft.PowerShell_profile.ps1 + Profile.d/*.ps1
#
# After running: open a NEW PowerShell session (or reload profile).

$ErrorActionPreference = 'Stop'

$pack   = Join-Path $PSScriptRoot '..\profile-source'
$packDn = Join-Path $pack 'Profile.d'
$liveDn = Join-Path (Split-Path $PROFILE -Parent) 'Profile.d'

Write-Host "==> pack source : $pack"
Write-Host "==> live profile : $PROFILE"

# Copy main profile
Copy-Item (Join-Path $pack 'Microsoft.PowerShell_profile.ps1') $PROFILE -Force
Write-Host "[OK]   Microsoft.PowerShell_profile.ps1" -ForegroundColor Green

# Ensure live Profile.d exists
if (-not (Test-Path $liveDn)) { New-Item -ItemType Directory -Force -Path $liveDn | Out-Null }

# Copy each snippet
$copied = 0
foreach ($f in (Get-ChildItem $packDn -Filter '*.ps1')) {
    $dst = Join-Path $liveDn $f.Name
    Copy-Item $f.FullName $dst -Force
    $copied++
}
Write-Host "[OK]   $copied snippets -> $liveDn" -ForegroundColor Green

Write-Host "`nOpen a new PowerShell session to activate the profile."