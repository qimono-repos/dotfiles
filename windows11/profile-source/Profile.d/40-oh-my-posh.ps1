# 40-oh-my-posh.ps1 — Catppuccin prompt for PowerShell (mirror 40-oh-my-posh.zsh).
$omp = Get-Command oh-my-posh -ErrorAction SilentlyContinue
if ($omp) {
    $theme = Join-Path $HOME '.config\oh-my-posh\catppuccin.omp.json'
    if (-not (Test-Path $theme)) {
        # bundled cache theme fallback (oh-my-posh installer payload)
        $cacheTheme = Join-Path $HOME '.cache\oh-my-posh\themes\catppuccin.omp.json'
        if (Test-Path $cacheTheme) { $theme = $cacheTheme }
    }
    if (Test-Path $theme) {
        oh-my-posh init pwsh --config $theme | Invoke-Expression
    } else {
        oh-my-posh init pwsh | Invoke-Expression
    }
}