# Filename: machine-discovery.ps1
# Description: Read-only host probe (Windows analog of machine-discovery.sh).
#   Records OS, hardware, Java/Android, tools on PATH; evidence for QA checklists.

Write-Host "=== machine-discovery: $(hostname) — $(Get-Date -Format 'yyyy-MM-dd HH:mm') ===`n"

Write-Host "--- OS ---"
Get-CimInstance Win32_OperatingSystem | Format-Table Caption,Version,OSArchitecture -AutoSize

Write-Host "--- Java (FROZEN) ---"
$java = "$env:JAVA_HOME\bin\java.exe"
if (Test-Path $java) {
    Write-Host "JAVA_HOME = $env:JAVA_HOME"
    & $java -version
} else {
    Write-Warning "JAVA_HOME not set or java.exe missing"
}

Write-Host "`n--- Android SDK ---"
$sdk = "$env:LOCALAPPDATA\Android\Sdk"
foreach ($comp in @('platform-tools\adb.exe','cmdline-tools','emulator','build-tools')) {
    $p = Join-Path $sdk $comp; $ok = (Test-Path $p)
    if ($ok) { "OK   $comp" } else { "MISS $comp" }
}

Write-Host "`n--- tools on PATH ---"
foreach ($bin in @('rg','fd','fzf','nvim','emacs','fastfetch','oh-my-posh','uv','python','node','bun','ollama','podman','tig','tree')) {
    $c = Get-Command $bin -ErrorAction SilentlyContinue
    if ($c) { "OK   {0} -> {1}" -f $bin, $c.Source } else { "MISS $bin" }
}

Write-Host "`n--- oh-my-posh theme ---"
$cat = Join-Path $HOME '.config\oh-my-posh\catppuccin.omp.json'
if (Test-Path $cat) { "OK   $cat" } else { "MISS $cat (using bundled default)" }