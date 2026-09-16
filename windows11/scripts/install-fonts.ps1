# Filename: install-fonts.ps1
# Description: Install minimal Caskaydia Cove Nerd Font TTFs per-user (no admin).
#   Downloads ONLY the 3.5 MB CascadiaCode.tar.xz from the Nerd Fonts v3.5.1
#   release instead of the 56.6 MB zip; installs Regular/Bold + Mono variants;
#   deletes the temp archive afterward.
#
# Idempotent. Fresh download each run (archive is removed after install).

$ErrorActionPreference = 'Stop'

$version = 'v3.5.1'
$tarUrl  = "https://github.com/ryanoasis/nerd-fonts/releases/download/$version/CascadiaCode.tar.xz"
$tmp     = Join-Path $env:TEMP 'nerd-fonts-cascadia'
$archive = Join-Path $tmp 'CascadiaCode.tar.xz'
$fontsDirBase = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$fontRegKey   = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

# Family groups: (font file name, display family)
$fontFiles = @(
    'CaskaydiaCoveNerdFont-Regular.ttf',
    'CaskaydiaCoveNerdFont-Bold.ttf',
    'CaskaydiaCoveNerdFont-Italic.ttf',
    'CaskaydiaCoveNerdFontMono-Regular.ttf',
    'CaskaydiaCoveNerdFontMono-Bold.ttf',
    'CaskaydiaCoveNerdFontMono-Italic.ttf'
)

New-Item -ItemType Directory -Force -Path $tmp | Out-Null
New-Item -ItemType Directory -Force -Path $fontsDirBase | Out-Null

if (-not (Test-Path $archive)) {
    Write-Host "downloading CascadiaCode.tar.xz ($(($tarUrl)))" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $tarUrl -OutFile $archive
}

# extract only the fonts we need (avoids unpacking 36 TTFs to disk)
$wantNames = $fontFiles -join '|'
$extractPath = Join-Path $tmp 'extract'
New-Item -ItemType Directory -Force -Path $extractPath | Out-Null
$hits = tar -tf $archive | Where-Object { $_ -match '^(' + $wantNames + ')$' }
if (-not $hits) { Write-Error 'expected Caskaydia Cove fonts not found in archive' }
foreach ($hit in $hits) {
    tar -xf $archive -C $extractPath $hit
}

# copy to user fonts dir + register per-user
foreach ($ttf in $hits) {
    $src = Join-Path $extractPath $ttf
    $dst = Join-Path $fontsDirBase $ttf
    Copy-Item -LiteralPath $src -Destination $dst -Force
    if (-not (Get-ItemProperty $fontRegKey -Name $ttf -ErrorAction SilentlyContinue)) {
        New-ItemProperty -Path $fontRegKey -Name $ttf -Value $dst -PropertyType String -Force | Out-Null
    }
    Write-Host "installed font: $ttf" -ForegroundColor Green
}

Remove-Item -Recurse -Force -Path $tmp -ErrorAction SilentlyContinue
Write-Host "`nOK: Caskaydia Cove (minimal) installed. Restart terminals to pick up." -ForegroundColor Green