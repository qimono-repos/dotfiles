# 42-fastfetch.ps1 — fastfetch at shell launch + after every `cls` (mirror 42-fastfetch.zsh).
# Interactive shells only.
if (-not (Get-Command fastfetch -ErrorAction SilentlyContinue)) { return }

# --- launch: run once, before the first prompt, then disarm ---
if (-not (Get-Variable -Name _fastfetchOnce -Scope Script -ErrorAction SilentlyContinue)) {
    fastfetch
    $script:_fastfetchOnce = $true
}

# --- every `cls`/`Clear-Host` reprints it ---
if (-not (Test-Path Function:\global:Clear-Host-Fastfetch)) {
    Set-Item Function:\Clear-Host -Value {
        [CmdletBinding()] param()
        $wrapped = { & Microsoft.PowerShell.Management\Clear-Host @PSBoundParameters }
        try { & $wrapped } catch { }
        fastfetch
    } -Option AllScope
}