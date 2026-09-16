# Filename: install-core.ps1
# Description: Tier-1 parity install for windows11 pack (Snapdragon ARM64).
#   winget batch mirroring ubuntu-len-yog-ARM64 CLI/editors/runtimes, plus
#   Node LTS and GNU Emacs (budget-approved, ~150 MB).
# Idempotent: skips packages already installed. Run as the normal user.
#
# NOT covered here: Java/Temurin (frozen), Ollama model (~7.2 GB, manual),
# quantum wheels (install-quantum.ps1), ghostty/font (budget-opt).

$ErrorActionPreference = 'Stop'

$packages = @(
    @{ Name = 'ripgrep';         Id = 'BurntSushi.ripgrep.MSVC' },
    @{ Name = 'fd';              Id = 'sharkdp.fd' },
    @{ Name = 'fzf';             Id = 'junegunn.fzf' },
    @{ Name = 'fastfetch';       Id = 'Fastfetch-cli.Fastfetch' },
    @{ Name = 'neovim';          Id = 'Neovim.Neovim' },
    @{ Name = 'oh-my-posh';      Id = 'JanDeDobbeleer.OhMyPosh' },
    @{ Name = 'python 3.13';     Id = 'Python.Python.3.13' },
    @{ Name = 'uv';              Id = 'astral-sh.uv' },
    @{ Name = 'node LTS';        Id = 'OpenJS.NodeJS.LTS' },
    @{ Name = 'emacs';           Id = 'GNU.Emacs' }
)

function Resolve-Id([string]$id) {
    $r = winget list --id $id --accept-source-agreements --disable-interactivity 2>$null
    return ($LASTEXITCODE -eq 0 -and ($r | Select-String -Pattern '^Name\s+Id' -Quiet))
}

Write-Host "=== windows11 tier-1 install (winget) ===" -ForegroundColor Cyan
foreach ($p in $packages) {
    $id = $p.Id
    $installed = winget list --id $id --accept-source-agreements --disable-interactivity 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[OK]   $($p.Name) already installed" -ForegroundColor Green
        continue
    }
    Write-Host "[..]   installing $($p.Name) ($id)..." -ForegroundColor Yellow
    winget install -e --id $id --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[DONE] $($p.Name)" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] $($p.Name) (exit $LASTEXITCODE)" -ForegroundColor Red
    }
}

Write-Host "`n--- verify on PATH ---" -ForegroundColor Cyan
foreach ($bin in @('rg', 'fd', 'fzf', 'fastfetch', 'nvim', 'oh-my-posh', 'python', 'uv', 'node', 'emacs')) {
    $c = Get-Command $bin -ErrorAction SilentlyContinue
    if ($c) { "OK   $bin -> $($c.Source)" } else { "MISS $bin" }
}