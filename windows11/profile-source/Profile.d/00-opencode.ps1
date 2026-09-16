# 00-opencode.ps1 — put the opencode CLI on PATH (mirror 00-opencode.zsh).
$oc = Join-Path $HOME '.opencode\bin'
if (Test-Path $oc) {
    $env:PATH = $oc + ';' + $env:PATH
}